import UIKit
import RxSwift
import CoreLocation

class LucaLocationPermissionWorkflow {

    /// It tries to retrieve the location permission `whenInUse`. It does not fail, it will just emit the best permission it could get from the user
    /// - parameter alertToShowBefore: A completable with an explanation why this feature is needed. Leave it empty to do nothing and to rely only on system prompts
    static func tryToAcquireLocationPermissionWhenInUse(
        alertToShowBefore infoAlert: Completable = Completable.empty()
    ) -> Single<CLAuthorizationStatus> {
        return LocationPermissionHandler.shared
            .permissionChanges
            .take(1)
            .flatMap { (currentStatus: CLAuthorizationStatus) -> Completable in
                // If it's already granted, complete here
                if currentStatus == .authorizedAlways || currentStatus == .authorizedWhenInUse {
                    return Completable.empty()
                }

                // If it's not determined yet, inform the user about the usage than prompt the system dialogue window
                if currentStatus == .notDetermined {
                    return infoAlert                                                                    // Show our info alert
                        .andThen(LocationPermissionHandler.shared.request(.authorizedWhenInUse))        // Prompt user
                        .andThen(LocationPermissionHandler.shared.permissionChanges.skip(1).take(1))    // Skip the first value (it's the current permission) and await the first value after that
                        .ignoreElementsAsCompletable()                                                  // Ignore elements and wait for complete
                }

                // If it's denied or unknown, inform user that he should change the settings
                return infoAlert                                                                        // Show our info alert
                    .subscribe(on: MainScheduler.instance)
                    .andThen(Completable.from { UIApplication.shared.openApplicationSettings() })
                    .andThen(UIApplication.shared.rx.didOpenApp.take(1))                                // Wait for user to come back
                    .ignoreElementsAsCompletable()                                                      // Complete
            }
            .ignoreElementsAsCompletable()// Up until this moment user should have granted the permissions, if not, force him to do it or leave it be.
            .andThen(LocationPermissionHandler.shared.permissionChanges.take(1))
            .asSingle()
            .debug("AUTH CHAIN TEST")
    }

    /// Tries to acquire location permission `always`
    /// - Parameters:
    ///   - alertToShowBefore: Alert to be shown before the user will be asked for the permission. Leave it empty to rely only on system prompts
    ///   - alertToShowIfDenied: Alert to be shown if user denies the permission. Leave it empty if no alert should be shown
    /// - Returns: A `Single` that emits the acquired permission
    static func tryToAcquireLocationPermissionAlways(
        alertToShowBefore infoAlert: Completable = Completable.empty(),
        alertToShowIfDenied locationDeniedAlert: Completable = Completable.empty(),
        alertsToShowForSelectedScenarios: ((CLAuthorizationStatus) -> Completable)? = nil
    ) -> Single<CLAuthorizationStatus> {

        LocationPermissionHandler.shared
            .permissionChanges
            .take(1)
            .flatMap { (currentStatus: CLAuthorizationStatus) -> Completable in
                if currentStatus == .notDetermined {
                    return infoAlert
                        .andThen(LocationPermissionHandler.shared.request(.authorizedWhenInUse))
                        .andThen(LocationPermissionHandler.shared.permissionChanges.skip(1).take(1)
                            .flatMap { permission -> Completable in
                                if permission == .denied {
                                    return locationDeniedAlert
                                } else {
                                    return handleOtherPermissions(permission: permission, alerts: alertsToShowForSelectedScenarios)
                                }
                            }
                        )
                        .ignoreElementsAsCompletable()
                }
                return handleOtherPermissions(permission: currentStatus, alerts: alertsToShowForSelectedScenarios)
            }
            .ignoreElementsAsCompletable()
            .andThen(LocationPermissionHandler.shared.permissionChanges.take(1))
            .asSingle()
    }

    private static func handleOtherPermissions(
        permission: CLAuthorizationStatus,
        alerts: ((CLAuthorizationStatus) -> Completable)? = nil) -> Completable {
        Single.just(permission)
            .flatMapCompletable { alerts?($0) ?? Completable.empty() }
            .andThen(Completable.from { UIApplication.shared.openApplicationSettings()}.subscribe(on: MainScheduler.instance))
            .andThen(UIApplication.shared.rx.didOpenApp.take(1).ignoreElementsAsCompletable())
    }

    /// It retrieves a single location. If not permitted, an error is thrown. It does not handle the permissions, it should be handled explicitly.
    static func retrieveSingleLocation() -> Single<CLLocation> {
        Single.from { LocationPermissionHandler.shared.currentPermission }
            .map { (authStatus: CLAuthorizationStatus) -> CLAuthorizationStatus in
                if !(authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse) {
                    throw NSError(domain: "User denied position", code: 0, userInfo: nil)
                }
                return authStatus
            }
            .flatMap { _ in ServiceContainer.shared.locationUpdater.locationChanges
                .map { locations in locations.filter({ Date().timeIntervalSince1970 - $0.timestamp.timeIntervalSince1970 < 60 }) }
                .map { locations in locations.sorted(by: { $0.timestamp > $1.timestamp }).first }
                .unwrapOptional()
                .take(1)
                .asSingle()
            }
            .do(onSubscribe: { DispatchQueue.main.async { ServiceContainer.shared.locationUpdater.start() } })
            .do(onDispose: { DispatchQueue.main.async { ServiceContainer.shared.locationUpdater.stop() } })
    }
}
