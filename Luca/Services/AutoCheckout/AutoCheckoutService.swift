import Foundation
import RxSwift
import RxAppState
import CoreLocation
import UIKit

enum AutoCheckoutServiceError: LocalizedTitledError {

    /// Feature is not available if user is not checked in or is checked in in a location that doesn't support this feature
    case featureNotAvailable

    /// This case informs that the feature cannot be enabled because user has denied needed location permission
    case permissionNotGranted

    /// This case informs that the feature was enabled before but stopped working because the once granted permission has been removed afterwards
    case permissionRemoved
}

extension AutoCheckoutServiceError {
    var localizedTitle: String {
        L10n.LocationCheckinViewController.AutoCheckoutPermissionDisabled.title
    }

    var errorDescription: String? {
        switch self {
        case .permissionNotGranted:
            return L10n.LocationCheckinViewController.AutoCheckoutPermissionDisabled.message
        case .permissionRemoved:
            return L10n.LocationCheckinViewController.AutoCheckoutPermissionDisabled.message
        case .featureNotAvailable:
            return "User not checked in or location doesn't support auto checkout"
        }
    }
}

class AutoCheckoutService {
    private let autoCheckoutEnabledKey = "AutoCheckoutService.enabled"
    private let keyValueRepo: KeyValueRepoProtocol
    private let traceIdService: TraceIdService

    private var disposeBag: DisposeBag?

    private let togglePublisher = PublishSubject<Bool>()

    private var regionDetectors: [RegionDetector] = []

    init(keyValueRepo: KeyValueRepoProtocol, traceIdService: TraceIdService, oldLucaPreferences: LucaPreferences) {
        self.keyValueRepo = keyValueRepo
        self.traceIdService = traceIdService

        // Migrate old settings
        if oldLucaPreferences.autoCheckout {
            _ = self.saveAndPublishToggle(true).andThen(Completable.from { oldLucaPreferences.autoCheckout = false }).subscribe()
        }
    }

    // MARK: - Public interface

    /// Emits current value on subscription and emits all changes upon updates
    ///
    /// Emits error, if the feature was once enabled but the requirements (currently permissions) are not met anymore. This feature will be toggled off shortly before the emission of the error.
    var isToggledOn: Observable<Bool> {
        isPermissionGranted.flatMapLatest { permissionGranted -> Observable<Bool> in
            if permissionGranted {
                return self.isToggledOnWithoutCheck
            } else {
                return self.isToggledOnWithoutCheck
                    .flatMap { isOn -> Observable<Bool> in
                        if isOn {
                            return self.toggleOff().andThen(Observable.error(AutoCheckoutServiceError.permissionRemoved))
                        }
                        return Observable.just(false)
                    }
            }
        }
    }

    /// Emits true, if all requirements are set and user can expect a checkout once reached out the region
    ///
    /// Requirements:
    /// - user is checked in
    /// - user toggled on this feature
    /// - user set location permission to `always`
    /// - listeners are enabled
    var isFeatureFullyWorking: Observable<Bool> {
        Observable.combineLatest(isAvailable, isPermissionGranted, isToggledOnWithoutCheck, resultSelector: { a, b, c in
            return a && b && c && self.isEnabled
        }).distinctUntilChanged()
    }

    /// Emits true if user is checked in and location supports auto check out feature, otherwise false
    var isAvailable: Observable<Bool> {
        let currentValue = traceIdService.isCurrentlyCheckedIn.asObservable()
        let changes = traceIdService.isCurrentlyCheckedInChanges
        return Observable.merge(currentValue, changes)
            .flatMap { isCheckedIn -> Single<Bool> in
                if isCheckedIn {
                    return self.traceIdService.fetchCurrentLocationInfo(checkLocalDBFirst: true).map { $0.geoLocationRequired }
                }
                return Single.just(false)
            }
            .distinctUntilChanged()
    }

    /// Are listeners enabled?
    var isEnabled: Bool { disposeBag != nil }

    func register(regionDetector: RegionDetector) {
        regionDetectors.append(regionDetector)
    }

    /// It toggles on the feature itself. It does not however enable the internal listeners. Use `enable()`to enable the listeners.
    /// - Parameter enabled: toggles on and off
    func toggleOn(
        alertToShowWhenNotAskedYet: Completable = Completable.empty(),
        alertToShowWhenDenied: Completable = Completable.empty(),
        alertForOthers: ((CLAuthorizationStatus) -> Completable)? = nil) -> Completable {
        availabilityCheck
            .andThen(permissionCheck.catch { _ in
                LucaLocationPermissionWorkflow.tryToAcquireLocationPermissionAlways(
                    alertToShowBefore: alertToShowWhenNotAskedYet,
                    alertToShowIfDenied: alertToShowWhenDenied,
                    alertsToShowForSelectedScenarios: alertForOthers
                    )
                    .asCompletable()
                    .andThen(self.permissionCheck)

                }
            )
        .andThen(saveAndPublishToggle(true))

        // If something fails, toggle the feature off and send the error further along the stream
        .catch { self.saveAndPublishToggle(false).andThen(Completable.error($0)) }
    }

    /// Toggles off the feature
    func toggleOff() -> Completable {
        saveAndPublishToggle(false)
    }

    /// It enables only the listeners. It will cause the feature to work once toggled on with `toggleOn`.
    func enable() {
        if isEnabled {
            return
        }
        let newDisposeBag = DisposeBag()
        Observable.merge(
            Observable.just(Void()),
            updateSignal
        )
        .flatMapLatest { _ in
            self.isFeatureFullyWorking
                .distinctUntilChanged()
                .flatMapLatest { isOn -> Completable in
                    if !isOn {
                        return Completable.empty()
                    }
                    return self.performRegionDetection().onErrorComplete()
                }
        }
        .subscribe()
        .disposed(by: newDisposeBag)

        // This feature should be toggled off at check out
        traceIdService
            .onCheckOutRx()
            .flatMap { _ in
                self.toggleOff()
                    .logError(self, "Automatic disabling auto checkout on checkout")
                    .onErrorComplete()
            }
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .subscribe()
            .disposed(by: newDisposeBag)

        disposeBag = newDisposeBag
    }

    /// Disables the listeners; it doesn't turn off the feature though
    func disable() {
        disposeBag = nil
    }

    // MARK: - Private helpers

    private var isPermissionGranted: Observable<Bool> {
        Observable.merge(
            Single.from { LocationPermissionHandler.shared.currentPermission }.asObservable(),
            LocationPermissionHandler.shared.permissionChanges
        )
        .map { $0 == .authorizedAlways }
        .distinctUntilChanged()
    }

    /// Toggles the setting, saves to the database and publishes.
    private func saveAndPublishToggle(_ value: Bool) -> Completable {
        keyValueRepo.store(autoCheckoutEnabledKey, value: value)
            .andThen(Completable.from { self.togglePublisher.onNext(value) })
    }

    /// Emits true if the toggle is or was on/off. It emits also all subsequent changes.
    ///
    /// On the contrary to `isToggledOn` it won't emit any errors and won't automatically toggle off this feature when the permissons are removed.
    private var isToggledOnWithoutCheck: Observable<Bool> {
        let currentValue = keyValueRepo.load(autoCheckoutEnabledKey, type: Bool.self)
            .catch { _ in Single.just(false) }
        return Observable.merge(currentValue.asObservable(), togglePublisher)
    }

    private func performRegionDetection() -> Completable {
        traceIdService.fetchCurrentLocationInfo(checkLocalDBFirst: true)
            .map { (location: Location) -> (CLLocationCoordinate2D, CLLocationDistance) in
                guard let long = location.lng,
                      let lat = location.lat,
                      location.geoLocationRequired else {
                    throw AutoCheckoutServiceError.featureNotAvailable
                }
                return (CLLocationCoordinate2D(latitude: lat, longitude: long), location.radius)
            }
            .asObservable()
            .flatMap { location in
                Observable.merge(self.regionDetectors.map { $0.isInsideRegion(center: location.0, radius: location.1) })
                    .filter { !$0 }
                    .flatMap { _ in
                        self.traceIdService.checkOut()
                            .retry(1) // Try once more when internet was occasionally down
                    }
            }
            .retry(maxAttempts: 30, delay: .seconds(2), scheduler: LucaScheduling.backgroundScheduler)
            .ignoreElementsAsCompletable()
    }

    // MARK: - Ready to use checks

    /// Completes if user is checked in and the location supports auto check out. Otherwise, emits an error `AutoCheckoutServiceError.featureNotAvailable`
    private var availabilityCheck: Completable {
        isAvailable
            .take(1)
            .asSingle()
            .do(onSuccess: { isAvailable in
                if !isAvailable {
                    throw AutoCheckoutServiceError.featureNotAvailable
                }
            })
            .asCompletable()
    }

    /// Single check; Completes if user grants the `always` location permission, otherwise emits an error `AutoCheckoutServiceError.permissionNotGranted`
    private var permissionCheck: Completable {
        isPermissionGranted
            .take(1)
            .asSingle()
            .do(onSuccess: { granted in
                if !granted {
                    throw AutoCheckoutServiceError.permissionNotGranted
                }
            })
            .asCompletable()
    }

    /// Emits a signal if something changed
    private var updateSignal: Observable<Void> {
        let permission = isPermissionGranted.distinctUntilChanged().map { _ in Void() }
        let toggle = togglePublisher.asObservable().distinctUntilChanged().map { _ in Void() }
        let availability = isAvailable.distinctUntilChanged().map { _ in Void() }
        let appState = UIApplication.shared.rx.applicationWillEnterForeground.map { _ in Void() }
        return Observable.merge(permission, toggle, availability, appState)
    }
}

extension AutoCheckoutService: UnsafeAddress, LogUtil {}
