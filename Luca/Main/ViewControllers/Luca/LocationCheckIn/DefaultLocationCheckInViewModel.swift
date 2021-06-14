import Foundation
import RxSwift
import RxCocoa
import CoreLocation

// swiftlint:disable:next type_body_length
class DefaultLocationCheckInViewModel: LocationCheckInViewModel {

    var alertSubject = PublishSubject<PrintableMessage>()
    var alert: Driver<PrintableMessage> {
        alertSubject.asDriver(onErrorDriveWith: Driver<PrintableMessage>.empty())
    }

    var isBusySubject = PublishSubject<Bool>()
    var isBusy: Driver<Bool> {
        isBusySubject.asDriver(onErrorJustReturn: false)
    }

    var isAutoCheckoutAvailableSubject = BehaviorSubject<Bool>(value: false)
    var isAutoCheckoutAvailable: Driver<Bool> {
        location
            .map { $0?.geoLocationRequired ?? false }
            .asDriver(onErrorJustReturn: false)
    }
    var isAutoCheckoutEnabledSubject = BehaviorRelay<Bool>(value: false)
    var isAutoCheckoutEnabled: BehaviorRelay<Bool> {
        isAutoCheckoutEnabledSubject
    }

    var isCheckedIn: Driver<Bool> {
        traceIdService.isCurrentlyCheckedInChanges
            .do(onNext: { if !$0 { self.notificationService.removePendingNotifications() } }) // Remove pending notifications
            .asDriver(onErrorJustReturn: true)
    }

    var locationName: Driver<String?> {
        location.map { $0?.locationName }.asDriver(onErrorDriveWith: Driver<String?>.empty())
    }

    var groupName: Driver<String?> {
        location.map { $0?.groupName }.asDriver(onErrorDriveWith: Driver<String?>.empty())
    }

    var timeSubject = BehaviorSubject<String>(value: "00:00:00")
    var time: Driver<String> {
        timeSubject.asDriver(onErrorJustReturn: "")
    }

    var checkInTime: Driver<String> {
        Single.from { L10n.Checkin.Slider.date(self.traceInfo.checkInDate.formattedDate) }.asDriver(onErrorJustReturn: "")
    }

    /// Emits true when the label with additional data should be hidden
    var additionalDataLabelHidden: Driver<Bool> {
        Single.from { self.traceIdService.additionalData == nil }.asDriver(onErrorJustReturn: true)
    }

    /// Contents of the additional data label
    var additionalDataLabelText: Driver<String> {
        Single.from {
            if let additionalData = self.traceIdService.additionalData as? TraceIdAdditionalData {
                return "Tischnummer: \(additionalData.table)"
            } else if self.traceIdService.additionalData as? PrivateMeetingQRCodeV3AdditionalData != nil {
                return ""
            } else if let additionalData = self.traceIdService.additionalData as? [String: String],
                      let first = additionalData.first {
                return "\(first.key): \(first.value)"
            }
            return ""
        }
        .asDriver(onErrorJustReturn: "")
    }

    func checkOut() -> Completable {
        let performTimeCheck = Completable.from {
            let secondsDiff = Date().timeIntervalSince1970 - self.traceInfo.checkInDate.timeIntervalSince1970
            if secondsDiff < 2 * 60.0 {
                throw PrintableError(
                    title: L10n.Navigation.Basic.hint,
                    message: L10n.LocationCheckinViewController.CheckOutFailed.LowDuration.message
                )
            }
        }

        let checkOutBackend = traceIdService.checkOut()
            .catch({ (error) in
                return Completable.error(
                    PrintableError(
                        title: L10n.Navigation.Basic.error,
                        message: L10n.LocationCheckinViewController.CheckOutFailed.General.message(error.localizedDescription)
                    )
                )
            })

        return performTimeCheck
            .andThen(checkOutBackend)
            .andThen(regionMonitor.stopRegionMonitoringRx())
            .andThen(notificationService.removePendingNotificationsRx())
            .subscribe(on: LucaScheduling.backgroundScheduler)
    }

    func release() {
        checkInTimer.delegate = nil
        checkInTimer.stop()
        disposeBag = nil
        viewController = nil
    }

    func connect(viewController: UIViewController) {
        self.viewController = viewController

        let newDisposeBag = DisposeBag()
        isAutoCheckoutEnabledSubject.accept(preferences.autoCheckout && locationPermissionHandler.currentPermission == .authorizedAlways)

        startLocationMonitoring()

        let handlePermissions = handlePermission()

        let fetchUserStatus = getUserStatus()

        let restoreCheckIn = UIApplication.shared.rx.applicationWillEnterForeground
            .do(onNext: { _ in
                self.checkInTimer.start(from: self.traceInfo.checkInDate)
                self.startLocationMonitoring()
            })
            .logError(self, "applicationWillEnterForeground")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .ignoreElementsAsCompletable()

        let permissionChanges = locationPermissionChanges()

        let autoCheckoutNotification = isAutoCheckoutEnabledSubject.flatMap {_ in
            NotificationPermissionHandler.shared.notificationSettings
        }

        let notificationPermissionChanges = Observable.merge(NotificationPermissionHandler.shared.permissionChanges, autoCheckoutNotification)
            .flatMap { permission in
                self.location
                    .map { $0?.geoLocationRequired ?? false }
                    .map {
                        (permission, $0)
                    }
            }
            .observe(on: MainScheduler.instance)
            .do(onNext: { permission, autocheckoutAvailable in
                let autoCheckoutOff = (autocheckoutAvailable && !self.preferences.autoCheckout) || !autocheckoutAvailable
                // Don't send checkout reminder if autocheckout is turned on.
                (permission == .authorized && autoCheckoutOff) ? self.notificationService.addNotification() : self.notificationService.removePendingNotifications()
            })
            .logError(self, "onNotificationPermissionChanges")
            .ignoreElementsAsCompletable()

        Completable.zip(
            fetchUserStatus,
            restoreCheckIn,
            notificationPermissionChanges,
            permissionChanges,
            handlePermissions,
            fetchCurrentLocation()
        )
            .subscribe(on: LucaScheduling.backgroundScheduler)
            .subscribe()
            .disposed(by: newDisposeBag)

        disposeBag = newDisposeBag

        setupCheckInTimer()
    }

    private func setupCheckInTimer() {
        checkInTimer.delegate = self
        let date = traceInfo.createdAtDate ?? traceInfo.checkInDate

        // This is a fix for the case when user set its time manually and is shifted towards future.
        // If this is the case, it selects the current date as the starting point to remedy the shift
        if Date().timeIntervalSince1970 - date.timeIntervalSince1970 < 0 {
            checkInTimer.start(from: Date())
        } else {
            checkInTimer.start(from: date)
        }
    }

    private func fetchCurrentLocation() -> Completable {
        traceIdService
            .fetchCurrentLocationInfo()
            .do(onSuccess: { location in
                self.location.onNext(location)
                let authStatus = self.locationUpdater.currentAuthorizationStatus
                if (authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse) && LucaPreferences.shared.autoCheckout {
                    self.regionMonitor.startRegionMonitoring()
                }
            })
            .do(onError: { error in
                self.alertSubject.onNext((title: L10n.Navigation.Basic.error,
                                          message: L10n.LocationCheckinViewController.LocationInfoFetchFailure.message(error.localizedDescription)))
            })
            .asObservable()
            .ignoreElementsAsCompletable()
            .onErrorComplete()
    }

    private func handlePermission() -> Completable {
        isAutoCheckoutEnabledSubject
            .asObservable()
            .deferredFilter { _ in self.isAutoCheckoutAvailable.asObservable().take(1).asSingle() }
            .do(onNext: { (enabled) in
                if enabled {
                    self.preferences.autoCheckout = true
                    self.regionMonitor.startRegionMonitoring()
                    self.locationUpdater.start()
                } else {
                    self.regionMonitor.stopRegionMonitoring()
                    self.preferences.autoCheckout = false
                }
            })
            .filter { $0 }
            .flatMap { _ in
                self.askForLocationPermission(viewController: self.viewController)
                    .do(onSuccess: { status in
                        if status != .authorizedAlways {
                            self.isAutoCheckoutEnabledSubject.accept(false)
                        }
                    })
            }
            .logError(self, "handlePermissions")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .ignoreElementsAsCompletable()
    }

    private func locationPermissionChanges() -> Completable {
        locationPermissionHandler.permissionChanges
            .observe(on: MainScheduler.instance)
            .do(onNext: { permission in
                if permission != .authorizedAlways && self.preferences.autoCheckout {
                    self.alertSubject.onNext((title: L10n.LocationCheckinViewController.AutoCheckoutPermissionDisabled.title,
                                              message: L10n.LocationCheckinViewController.AutoCheckoutPermissionDisabled.message))

                    self.isAutoCheckoutEnabledSubject.accept(false)
                }
            })
            .logError(self, "onPermissionChanges")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .ignoreElementsAsCompletable()
    }

    private func getUserStatus() -> Completable {
        Observable<Int>
            .interval(.seconds(10), scheduler: LucaScheduling.backgroundScheduler)
            .flatMapFirst { _ in
                self.fetchUserStatus()
                    .logError(self, "fetchingUserStatus.intern")
                    .onErrorComplete() // ignore error as this task is completely invisible to user and it will be restarted by the interval
            }
            .logError(self, "fetchingUserStatus")
            .ignoreElementsAsCompletable()
    }

    private let traceInfo: TraceInfo
    private let traceIdService: TraceIdService
    private let checkInTimer: CheckinTimer
    private let preferences: LucaPreferences
    private let locationUpdater: LocationUpdater
    private let regionMonitor: RegionMonitor
    private let notificationService: NotificationService
    private let locationPermissionHandler: LocationPermissionHandler
    private let location = BehaviorSubject<Location?>(value: nil)

    private var disposeBag: DisposeBag?

    private var viewController: UIViewController! = nil

    init(traceInfo: TraceInfo,
         traceIdService: TraceIdService,
         timer: CheckinTimer,
         preferences: LucaPreferences,
         locationUpdater: LocationUpdater,
         locationPermissionHandler: LocationPermissionHandler,
         regionMonitor: RegionMonitor,
         notificationService: NotificationService) {
        self.traceInfo = traceInfo
        self.traceIdService = traceIdService
        self.checkInTimer = timer
        self.preferences = preferences
        self.locationUpdater = locationUpdater
        self.locationPermissionHandler = locationPermissionHandler
        self.regionMonitor = regionMonitor
        self.notificationService = notificationService
    }

    private func retrieveUserID() -> Single<UUID> {
        Single.from {
            if let uuid = self.preferences.uuid {
                return uuid
            }
            throw NSError(domain: "Couldn't obtain user ID", code: 0, userInfo: nil)
        }
    }

    private func askForLocationPermission(viewController: UIViewController) -> Single<CLAuthorizationStatus> {
        let deniedPermissionAlert = alertAskingToChangePermissionInSettings(viewController: viewController)
        let infoAlert = alertBeforeAskingLocationPermissionForCheckout(viewController: viewController)
        return LucaLocationPermissionWorkflow.tryToAcquireLocationPermissionAlways(alertToShowBefore: infoAlert, alertToShowIfDenied: deniedPermissionAlert)
    }

    private func alertBeforeAskingLocationPermissionForCheckout(viewController: UIViewController) -> Completable {
        return AlertViewControllerFactory.createLocationAccessInformationViewController(presentedOn: viewController)
            .ignoreElementsAsCompletable()
            .subscribe(on: MainScheduler.instance)
    }

    private func alertAskingToChangePermissionInSettings(viewController: UIViewController) -> Completable {
        Single.from { self.locationPermissionHandler.currentPermission }
            .flatMapCompletable { _ -> Completable in
                return UIAlertController.infoAlertRx(
                    viewController: viewController,
                    title: L10n.LocationCheckinViewController.Permission.Change.title,
                    message: L10n.LocationCheckinViewController.Permission.Change.message)
                    .ignoreElementsAsCompletable()
            }
            .subscribe(on: MainScheduler.instance)
    }

    private func alertAfterLocationPermissionDeniedForCheckout(viewController: UIViewController) -> Completable {
        var message = L10n.LocationCheckinViewController.Permission.Denied.messageWithoutName
        if let name = (try? self.location.value())?.formattedName {
            message = L10n.LocationCheckinViewController.Permission.Denied.message(name)
        }
        return UIAlertController.infoAlertRx(
            viewController: viewController,
            title: L10n.Navigation.Basic.error,
            message: message)
        .ignoreElementsAsCompletable()
            .subscribe(on: MainScheduler.instance)
    }

    private func fetchUserStatus() -> Completable {
        // Trigger this just to check up if backend has checked out the user
        traceIdService.fetchTraceStatusRx()
            .asObservable()
            .ignoreElementsAsCompletable()

    }

    /// It starts location monitoring only when its allowed
    private func startLocationMonitoring() {
        let authStatus = locationUpdater.currentAuthorizationStatus
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            locationUpdater.start()
        }
    }

    private func stopLocationMonitoring() {
        locationUpdater.stop()
    }
}

extension DefaultLocationCheckInViewModel: TimerDelegate {
    func timerDidTick() {
        timeSubject.onNext(checkInTimer.counter.formattedTimeString)
    }
}

extension DefaultLocationCheckInViewModel: UnsafeAddress, LogUtil {}
