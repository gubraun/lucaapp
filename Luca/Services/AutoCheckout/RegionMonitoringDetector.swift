import RxSwift
 import CoreLocation

 class RegionMonitoringDetector: RegionDetector {

    private let locationUpdater: LocationUpdater

    init(locationUpdater: LocationUpdater) {
        self.locationUpdater = locationUpdater
    }

    func isInsideRegion(center: CLLocationCoordinate2D, radius: CLLocationDistance) -> Observable<Bool> {
        Single.from {
            let region = CLCircularRegion(center: center, radius: radius, identifier: "RegionMonitoringDetector.\(center.latitude).\(center.longitude)")

            region.notifyOnEntry = true
            region.notifyOnExit = true
            return region
        }
        .asObservable()
        .flatMap { region in
            Completable.from { self.locationUpdater.startMonitoring(region: region) }
                .subscribe(on: MainScheduler.instance)
                .andThen(Observable.merge(
                    self.onDidEnter(region: region).map { _ in true },
                    self.onDidExit(region: region).map { _ in false }
                )
                .do(onDispose: {
                    self.stopMonitoring()
                }))
        }
    }

    private func onDidEnter(region: CLRegion) -> Observable<Void> {
        locationUpdater.onDidEnterRegion.filter { $0.identifier == region.identifier }.map { _ in Void() }
    }

    private func onDidExit(region: CLRegion) -> Observable<Void> {
        locationUpdater.onDidExitRegion.filter { $0.identifier == region.identifier }.map { _ in Void() }
    }

    private func stopMonitoring() {
        DispatchQueue.main.async {
            self.locationUpdater.monitoredRegions
                .filter { self.isIdentifierLocationRegion($0.identifier) }
                .forEach { self.locationUpdater.stopMonitoring(region: $0)}
        }
    }

    /// Returns true if this identifier is any location identifier
    private func isIdentifierLocationRegion(_ identifier: String) -> Bool {
        return identifier.contains("RegionMonitoringDetector.")
    }

 }
