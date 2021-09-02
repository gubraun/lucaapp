import RxSwift
import CoreLocation

protocol RegionDetector {

    /// Observes given region and emits true if the state changes to inside and false when user left the region. It may or may not emit the current state upon subscription
    ///
    /// This mechanism will enable and disable underlying mechanisms upon subscription and disposal. (eg. Region monitoring or location updates)
    /// - Parameters:
    ///   - center: Center of observed region
    ///   - radius: Radius of observed region
    func isInsideRegion(center: CLLocationCoordinate2D, radius: CLLocationDistance) -> Observable<Bool>
}
