import CoreLocation
import RxSwift

extension LocationUpdater {
    /// Emits all location updates. The subscription does not trigger any permission nor it does enable the location updates itself. It solely wraps the updates into an rx observable. It emits buffered locations on subscribe.
    var locationChanges: Observable<[CLLocation]> {
        let bufferred = Single.from { self.bufferredLocations }.asObservable()
        let newLocations = NotificationCenter.default.rx.notification(NSNotification.Name(LocationUpdater.onDidUpdateLocations), object: self)
            .map { $0.userInfo }
            .unwrapOptional(errorOnNil: true)
            .map { $0["locations"] as? [CLLocation] }
            .unwrapOptional(errorOnNil: true)

        return Observable.merge(bufferred, newLocations)
    }

    var onDidEnterRegion: Observable<CLRegion> {
        return NotificationCenter.default.rx.notification(NSNotification.Name(LocationUpdater.onDidEnterRegion), object: self)
            .map { $0.userInfo }
            .unwrapOptional(errorOnNil: true)
            .map { $0["region"] as? CLRegion }
            .unwrapOptional(errorOnNil: true)
    }

    var onDidExitRegion: Observable<CLRegion> {
        return NotificationCenter.default.rx.notification(NSNotification.Name(LocationUpdater.onDidExitRegion), object: self)
            .map { $0.userInfo }
            .unwrapOptional(errorOnNil: true)
            .map { $0["region"] as? CLRegion }
            .unwrapOptional(errorOnNil: true)
    }
}
