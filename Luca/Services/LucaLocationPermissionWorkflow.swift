import UIKit
import RxSwift
import CoreLocation

class LucaLocationPermissionWorkflow {

    /// It tries to retrieve the location permission whenInUse. It does not fail, it will just emit the best permission it could get from the user
    /// - parameter alertToShowBefore: A completable with an explanation why this feature is needed. Leave it empty to do nothing and to rely only on system prompts
    static func tryToAcquireLocationPermissionWhenInUse(alertToShowBefore infoAlert: Completable = Completable.empty()) -> Single<CLAuthorizationStatus> {
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
                        .ignoreElements()                                                               // Ignore elements and wait for complete
                }

                // If it's denied or unknown, inform user that he should change the settings
                return infoAlert                                                                        // Show our info alert
                    .andThen(Completable.from { UIApplication.shared.openApplicationSettings() })
                    .andThen(UIApplication.shared.rx.didOpenApp.take(1))                                // Wait for user to come back
                    .ignoreElements()                                                                   // Complete
            }
            .ignoreElements()// Up until this moment user should have granted the permissions, if not, force him to do it or leave it be.
            .andThen(LocationPermissionHandler.shared.permissionChanges.take(1))
            .asSingle()
            .debug("AUTH CHAIN TEST")
    }

    static func tryToAcquireLocationPermissionAlways(alertToShowBefore infoAlert: Completable = Completable.empty(),
                                                     alertToShowIfDenied locationDeniedAlert: Completable = Completable.empty()) -> Single<CLAuthorizationStatus> {
        return LocationPermissionHandler.shared
            .permissionChanges
            .take(1)
            .flatMap { (currentStatus: CLAuthorizationStatus) -> Observable<CLAuthorizationStatus> in
                if currentStatus == .notDetermined {
                    return infoAlert
                        .andThen(LocationPermissionHandler.shared.request(.authorizedWhenInUse))
                        .andThen(LocationPermissionHandler.shared.permissionChanges.skip(1).take(1))
                }
                return Observable.just(currentStatus)
            }.flatMap { permission -> Observable<Void> in
                if permission != .authorizedAlways {
                    return locationDeniedAlert
                        .andThen(Completable.from { UIApplication.shared.openApplicationSettings()})
                        .andThen(UIApplication.shared.rx.didOpenApp.take(1))
                }
                return Observable.empty()
            }.ignoreElements()
            .andThen(LocationPermissionHandler.shared.permissionChanges.take(1))
            .asSingle()
    }

    /// It retrieves single location. If not permitted, an error is thrown. It does not handle the permissions, it should be handled explicitly.
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
            .do(onSuccess: { _ in DispatchQueue.main.async { ServiceContainer.shared.locationUpdater.stop() } })
    }
}
