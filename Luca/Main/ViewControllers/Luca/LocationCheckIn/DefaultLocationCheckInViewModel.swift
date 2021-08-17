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
        Single.from { L10n.Checkin.Slider.date(self.traceInfo.checkInDate.formattedDateTime) }.asDriver(onErrorJustReturn: "")
    }

    var checkInTimeDate: Single<Date> {
        Single.from { self.traceInfo.checkInDate }
    }

    /// Emits true when the label with additional data should be hidden
    var additionalDataLabelHidden: Driver<Bool> {
        Single.from { self.traceIdService.additionalData == nil }.asDriver(onErrorJustReturn: true)
    }

    /// Contents of the additional data label
    var additionalDataLabelText: Driver<String> {
        Single.from {
            if let additionalData = self.traceIdService.additionalData as? TraceIdAdditionalData {
                return L10n.LocationCheckinViewController.AdditionalData.table(additionalData.table)
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
                var errorTitle = L10n.Navigation.Basic.error
                if let localizedError = error as? LocalizedTitledError {
                    errorTitle = localizedError.localizedTitle
                }

                return Completable.error(
                    PrintableError(
                        title: errorTitle,
                        message: error.localizedDescription
                    )
                )
            })

        return performTimeCheck
            .andThen(checkOutBackend)
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

        autoCheckoutService.isToggledOn
            .observe(on: MainScheduler.instance)
            .catch { error in
            let vc: UIViewController
            if let localizedError = error as? LocalizedTitledError {
                vc = UIAlertController.infoAlert(
                    title: localizedError.localizedTitle,
                    message: localizedError.localizedDescription
                )
            } else {
                vc = UIAlertController.infoAlert(
                    title: L10n.Navigation.Basic.error,
                    message: L10n.General.Failure.Unknown.message(error.localizedDescription)
                )
            }
            self.viewController.present(vc, animated: true, completion: nil)
            return Observable.error(error)
        }
        .retry(delay: .milliseconds(100), scheduler: MainScheduler.instance)
        .bind(to: isAutoCheckoutEnabledSubject)
        .disposed(by: newDisposeBag)

        isAutoCheckoutEnabledSubject
            .asObservable()
            .distinctUntilChanged()
            .flatMap { isEnabled -> Completable in
                if isEnabled {
                    return self.autoCheckoutService.toggleOn(
                        alertToShowWhenNotAskedYet: self.alertBeforeAskingLocationPermissionForCheckout(viewController: self.viewController),
                        alertForOthers: { _ in self.alertAskingToChangePermissionInSettings(viewController: self.viewController)}
                    ).catch { _ in Completable.empty() }
                } else {
                    return self.autoCheckoutService.toggleOff().catch { _ in Completable.empty() }
                }
            }
            .subscribe()
            .disposed(by: newDisposeBag)

        let fetchUserStatus = getUserStatus()

        let restoreCheckIn = UIApplication.shared.rx.applicationWillEnterForeground
            .do(onNext: { _ in
                self.checkInTimer.start(from: self.traceInfo.checkInDate)
            })
            .logError(self, "applicationWillEnterForeground")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .ignoreElementsAsCompletable()

        let loadCurrentlySavedLocation = self.traceIdService.loadCurrentLocationInfo()
            .do(onSuccess: { self.location.onNext($0) })
            .asObservable()
            .onErrorComplete()
            .ignoreElementsAsCompletable()

        Completable.zip(
            fetchUserStatus,
            restoreCheckIn,
            fetchCurrentLocation(),
            loadCurrentlySavedLocation
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
            })
            .do(onError: { error in
                self.alertSubject.onNext((title: L10n.Navigation.Basic.error,
                                          message: L10n.LocationCheckinViewController.LocationInfoFetchFailure.message(error.localizedDescription)))
            })
            .asObservable()
            .ignoreElementsAsCompletable()
            .onErrorComplete()
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
    private let autoCheckoutService: AutoCheckoutService
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
         autoCheckoutService: AutoCheckoutService,
         notificationService: NotificationService) {
        self.traceInfo = traceInfo
        self.traceIdService = traceIdService
        self.checkInTimer = timer
        self.preferences = preferences
        self.locationUpdater = locationUpdater
        self.locationPermissionHandler = locationPermissionHandler
        self.autoCheckoutService = autoCheckoutService
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
        return ViewControllerFactory.Alert.createLocationAccessInformationViewController(presentedOn: viewController)
            .ignoreElementsAsCompletable()
            .subscribe(on: MainScheduler.instance)
    }

    private func alertAskingToChangePermissionInSettings(viewController: UIViewController) -> Completable {
        UIAlertController.infoAlertRx(
                    viewController: viewController,
                    title: L10n.LocationCheckinViewController.Permission.Change.title,
                    message: L10n.LocationCheckinViewController.Permission.Change.message)
                    .ignoreElementsAsCompletable()
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
