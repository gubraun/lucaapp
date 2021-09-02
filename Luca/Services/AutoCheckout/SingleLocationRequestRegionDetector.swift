import RxSwift
import CoreLocation
import RxAppState

class SingleLocationRequestRegionDetector: RegionDetector {
    private let locationUpdater: LocationUpdater

    var allowedAppStates: [AppState]

    init(locationUpdater: LocationUpdater, allowedAppStates: [AppState]) {
        self.locationUpdater = locationUpdater
        self.allowedAppStates = allowedAppStates
    }

    func isInsideRegion(center: CLLocationCoordinate2D, radius: CLLocationDistance) -> Observable<Bool> {
        UIApplication.shared.rx.currentAndChangedAppState
            .flatMapLatest { appState -> Observable<Bool> in
                if self.allowedAppStates.contains(appState) {
                    return self.performCheck(center: center, radius: radius)
                }
                return Observable.empty()
            }
    }

    private func performCheck(center: CLLocationCoordinate2D, radius: CLLocationDistance) -> Observable<Bool> {
        locationUpdater.locationChanges
            .do(onSubscribe: { self.locationUpdater.requestCurrentLocation() })
            .compactMap { (positions: [CLLocation]) -> CLLocation? in
                positions

                    // Take only last 5 minutes positions
                    .filter { Date().timeIntervalSince1970 - $0.timestamp.timeIntervalSince1970 < 60.0 * 5.0 }

                    .sorted { $0.timestamp > $1.timestamp }

                    // Take only the newest position
                    .first
            }
            .map { (position: CLLocation) in

                // Check if the position is inside of the region (given the accuracy)
                position.distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude)) < position.horizontalAccuracy + radius
            }
            .distinctUntilChanged()
    }

}
