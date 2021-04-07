import Foundation
import RxSwift
import RxCocoa
import CoreLocation

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
            .do(onNext: { if !$0 { self.notificationService.removePendingNotifications() } }) //Remove pending notifications
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
            if let additionalData = self.traceIdService.additionalData as? TraceIdAdditionalData{
                return "Tischnummer: \(additionalData.table)"
            } else if let _ = self.traceIdService.additionalData as? PrivateMeetingQRCodeV3AdditionalData {
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
            if (Date().timeIntervalSince1970 - self.traceInfo.checkInDate.timeIntervalSince1970) < 2 * 60.0 {
                throw PrintableError(title: L10n.Navigation.Basic.hint,
                                     message: L10n.LocationCheckinViewController.CheckOutFailed.LowDuration.message)
            }
        }
        
        let checkOutBackend = traceIdService.checkOutRx()
            .catchError({ (error) in
                return Completable.error(PrintableError(
                                            title: L10n.Navigation.Basic.error,
                                            message: L10n.LocationCheckinViewController.CheckOutFailed.General.message(error.localizedDescription)))
            })
        
        return performTimeCheck
            .andThen(checkOutBackend)
            .andThen(regionMonitor.stopRegionMonitoringRx())
            .andThen(notificationService.removePendingNotificationsRx())
            .subscribeOn(LucaScheduling.backgroundScheduler)
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
        location.onNext(traceIdService.currentLocationInfo)
        startLocationMonitoring()
        
        let handlePermissions = isAutoCheckoutEnabledSubject
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
            .flatMap { enabled in
                self.askForLocationPermission(viewController: self.viewController)
                    .do(onSuccess: { status in
                        if status != .authorizedAlways {
                            self.isAutoCheckoutEnabledSubject.accept(false)
                        }
                    })
            }
            .logError(self, "handlePermissions")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .ignoreElements()
        
        let fetchUserStatus = Observable<Int>
            .interval(.seconds(10), scheduler: LucaScheduling.backgroundScheduler)
            .flatMapFirst { _ in
                self.fetchUserStatus()
                    .logError(self, "fetchingUserStatus.intern")
                    .onErrorComplete() //ignore error as this task is completely invisible to user and it will be restarted by the interval
            }
            .logError(self, "fetchingUserStatus")
            .ignoreElements()
        
        let restoreCheckIn = UIApplication.shared.rx.applicationWillEnterForeground
            .do(onNext: { _ in
                self.checkInTimer.start(from: self.traceInfo.checkInDate)
                self.startLocationMonitoring()
            })
            .logError(self, "applicationWillEnterForeground")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .ignoreElements()
        
        let permissionChanges = locationPermissionHandler.permissionChanges
            .observeOn(MainScheduler.instance)
            .do(onNext: { permission in
                if permission != .authorizedAlways && self.preferences.autoCheckout {
                    self.alertSubject.onNext((title: L10n.LocationCheckinViewController.AutoCheckoutPermissionDisabled.title,
                                              message: L10n.LocationCheckinViewController.AutoCheckoutPermissionDisabled.message))
                    
                    self.isAutoCheckoutEnabledSubject.accept(false)
                }
            })
            .logError(self, "onPermissionChanges")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .ignoreElements()
        
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
            .observeOn(MainScheduler.instance)
            .do(onNext: { permission, autocheckoutAvailable in
                let autoCheckoutOff = (autocheckoutAvailable && !self.preferences.autoCheckout) || !autocheckoutAvailable
                // Don't send checkout reminder if autocheckout is turned on.
                (permission == .authorized && autoCheckoutOff) ? self.notificationService.addNotification() : self.notificationService.removePendingNotifications()
            })
            .logError(self, "onNotificationPermissionChanges")
            .ignoreElements()
        
        Completable.zip(fetchUserStatus, restoreCheckIn, notificationPermissionChanges, permissionChanges, handlePermissions)
            .subscribeOn(LucaScheduling.backgroundScheduler)
            .subscribe()
            .disposed(by: newDisposeBag)
        
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
            .ignoreElements()
            .onErrorComplete()
            .subscribe()
            .disposed(by: newDisposeBag)
        
        disposeBag = newDisposeBag
        
        checkInTimer.delegate = self
        let date = traceInfo.createdAtDate ?? traceInfo.checkInDate
        
        //This is a fix for the case when user set its time manually and is shifted towards future.
        //If this is the case, it selects the current date as the starting point to remedy the shift
        if Date().timeIntervalSince1970 - date.timeIntervalSince1970 < 0 {
            checkInTimer.start(from: Date())
        } else {
            checkInTimer.start(from: date)
        }
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
    
    private var disposeBag: DisposeBag? = nil
    
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
    
    private func retrieveCurrentLocation(viewController: UIViewController) -> Single<CLLocation> {
        let alert = alertBeforeAskingLocationPermissionForCheckout(viewController: viewController)
        return LucaLocationPermissionWorkflow.tryToAcquireLocationPermissionWhenInUse(alertToShowBefore: alert)
            .flatMap { authStatus -> Single<CLLocation> in
                if !(authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse) {
                    return self.alertAfterLocationPermissionDeniedForCheckout(viewController: viewController)
                        .andThen(Single.error(NSError(domain: "User denied position permission", code: 0, userInfo: nil)))
                }
                return LucaLocationPermissionWorkflow.retrieveSingleLocation()
            }
    }
    
    private func askForLocationPermission(viewController: UIViewController) -> Single<CLAuthorizationStatus> {
        let alert = alertAskingToChangePermissionInSettings(viewController: viewController)
        return LucaLocationPermissionWorkflow.tryToAcquireLocationPermissionAlways(alertToShow: alert)
    }
    
    private func alertBeforeAskingLocationPermissionForCheckout(viewController: UIViewController) -> Completable {
        var message = L10n.LocationCheckinViewController.Permission.BeforePrompt.messageWithoutName
        if let name = (try? self.location.value())?.formattedName {
            message = L10n.LocationCheckinViewController.Permission.BeforePrompt.message(name)
        }
        return UIAlertController.infoAlertRx(
                viewController: viewController,
                title: L10n.LocationCheckinViewController.Permission.BeforePrompt.title,
                message: message)
            .ignoreElements()
            .subscribeOn(MainScheduler.instance)
    }
    
    private func alertAskingToChangePermissionInSettings(viewController: UIViewController) -> Completable {
        Single.from { self.locationPermissionHandler.currentPermission }
            .flatMapCompletable { authStatus -> Completable in
                return UIAlertController.infoAlertRx(
                    viewController: viewController,
                    title: L10n.LocationCheckinViewController.Permission.Change.title,
                    message: L10n.LocationCheckinViewController.Permission.Change.message)
                    .ignoreElements()
            }
            .subscribeOn(MainScheduler.instance)
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
        .ignoreElements()
        .subscribeOn(MainScheduler.instance)
    }
    
    private func fetchUserStatus() -> Completable {
        //Trigger this just to check up if backend has checked out the user
        traceIdService.fetchTraceStatusRx()
            .asObservable()
            .ignoreElements()
        
    }
    
    /// It starts location monitoring only when its allowed
    private func startLocationMonitoring() {
        let authStatus = locationUpdater.currentAuthorizationStatus
        if (authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse) {
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
