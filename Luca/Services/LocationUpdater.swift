import UIKit
import CoreLocation

public class LocationUpdater: NSObject {
    public typealias CurrentLocationCompletion = (CLLocation) -> Void
    // MARK: - Events
    public static let onDidUpdateLocations: String = "LocationUpdater.onDidUpdateLocations"
    // MARK: -
    private var locationManager: CLLocationManager

    private var lastPrompt = Date()

    private var currentLocationRequestCompletions: [CurrentLocationCompletion] = []

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
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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
        print("LOCATION START")
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }

    public func stop() {
        print("LOCATION STOP")
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    public func requestCurrentLocation(completion: @escaping CurrentLocationCompletion) {
        currentLocationRequestCompletions.append(completion)
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
        locationManager.startMonitoring(for: region)
    }

    public func stopMonitoring(region: CLRegion) {
        locationManager.stopMonitoring(for: region)
    }

}

// MARK: - CoreLocation delegate
extension LocationUpdater: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        bufferredLocations.append(contentsOf: locations)
        print("NEW LOCATIONS!. Current buffer size: \(bufferredLocations.count)")

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
        #if DEBUG
        NotificationScheduler.shared.scheduleNotification(title: "Did enter region", message: "")
        #endif
        log("Entered region: \(region)")
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        #if DEBUG
        NotificationScheduler.shared.scheduleNotification(title: "Did exit region", message: "")
        #endif
        log("Exitted region: \(region)")

        self.log("Geofence: trying to check out...")
        if ServiceContainer.shared.traceIdService.isCurrentlyCheckedIn, LucaPreferences.shared.autoCheckout {
            self.log("Geofence: sending check out request")
            ServiceContainer.shared.traceIdService.checkOut {
                self.log("Geofence: on check out: \(ServiceContainer.shared.traceIdService.isCurrentlyCheckedIn)")
            } failure: { (error) in
                self.log("Geofence: on check out error: \(error)", entryType: .error)
            }

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
