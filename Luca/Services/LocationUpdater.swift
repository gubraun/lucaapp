import UIKit
import CoreLocation
import RxSwift

public class LocationUpdater: NSObject {
    public typealias CurrentLocationCompletion = (CLLocation) -> Void
    // MARK: - Events
    public static let onDidUpdateLocations: String = "LocationUpdater.onDidUpdateLocations"
    public static let onDidEnterRegion: String = "LocationUpdater.onDidEnterRegion"
    public static let onDidExitRegion: String = "LocationUpdater.onDidExitRegion"
    // MARK: -
    private var locationManager: CLLocationManager

    private var lastPrompt = Date()

    private var currentLocationRequestCompletions: [CurrentLocationCompletion] = []

    /// Delays the delivery of events. A nasty workaround for the "Late observer" problem.
    var delayRegionEvents: TimeInterval = 1.0

    var monitoredRegions: Set<CLRegion> {
        return locationManager.monitoredRegions
    }

    /// Locations saved previously. Used to mitigate the problem of long wait times.
    private(set) var bufferredLocations: [CLLocation] = []

    var currentAuthorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    public override init() {
        self.locationManager = CLLocationManager()
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.activityType = .fitness
    }

    public func requestAuthorization(always: Bool) {
        if always {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    public func start() {
        print("LOCATION START: is main thread \(Thread.current.isMainThread)")
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }

    public func stop() {
        print("LOCATION STOP: is main thread \(Thread.current.isMainThread)")
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    public func requestCurrentLocation(completion: CurrentLocationCompletion? = nil) {
        if let completion = completion { currentLocationRequestCompletions.append(completion) }
        locationManager.requestLocation()
    }

    public func checkLocationServices() -> PermissionState {
        guard CLLocationManager.locationServicesEnabled() else {
            return .serviceDisabled
        }
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            return .undetermined
        case .authorizedAlways:
            return .granted
        default:
            return .restricted
        }
    }

    public func startMonitoring(region: CLRegion) {
        #if DEBUG
        print("MONITOR START: is main thread \(Thread.current.isMainThread)")
        #endif

        locationManager.startMonitoring(for: region)

        #if DEBUG
        print("Monitored regions: \(locationManager.monitoredRegions)")
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(500)) {
            print("Monitored regions DELAYED: \(self.locationManager.monitoredRegions)")
        }
        #endif
    }

    public func stopMonitoring(region: CLRegion) {
        #if DEBUG
        print("REGION MONITOR STOP \(region.identifier): is main thread \(Thread.current.isMainThread)")
        #endif

        locationManager.stopMonitoring(for: region)

        #if DEBUG
        print("Monitored regions: \(locationManager.monitoredRegions)")
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(500)) {
            print("Monitored regions DELAYED: \(self.locationManager.monitoredRegions)")
        }
        #endif
    }

}

// MARK: - CoreLocation delegate
extension LocationUpdater: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        bufferredLocations.append(contentsOf: locations)
        print("NEW LOCATIONS!. Current buffer size: \(bufferredLocations.count)")
        for location in locations {
            print("\tLocation: \(location)")
        }

        if let location = locations.last {
            for completion in currentLocationRequestCompletions {
                completion(location)
            }
            currentLocationRequestCompletions.removeAll()
        }
        NotificationCenter.default.post(name: Notification.Name(Self.onDidUpdateLocations), object: self, userInfo: ["locations": locations])
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log("LocationUpdater: didFail \(error)", entryType: .error)
    }

    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        log("LocationUpdater: monitoringDidFailFor regio: \(region!.identifier)", entryType: .error)
    }

    public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        log("LocationUpdater: rangingBeaconsDidFailFor region with error: \(error)", entryType: .error)
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(Int(delayRegionEvents * 1000.0))) {
            #if DEBUG
            NotificationScheduler.shared.scheduleNotification(title: "Did enter region", message: region.identifier)
            #endif
            self.log("Entered region: \(region)")
            NotificationCenter.default.post(name: Notification.Name(Self.onDidEnterRegion), object: self, userInfo: ["region": region])
        }
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(Int(delayRegionEvents * 1000.0))) {
            #if DEBUG
            NotificationScheduler.shared.scheduleNotification(title: "Did exit region", message: region.identifier)
            #endif
            self.log("Exitted region: \(region)")
            NotificationCenter.default.post(name: Notification.Name(Self.onDidExitRegion), object: self, userInfo: ["region": region])
        }
    }

}

extension CLAuthorizationStatus: CustomStringConvertible {

    public var description: String {
        switch self {
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        case .denied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        @unknown default:
            return "unknown"
        }
    }

}

extension LocationUpdater: UnsafeAddress, LogUtil {}
