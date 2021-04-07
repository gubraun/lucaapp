import Foundation
import CoreLocation
import RxSwift

public class RegionMonitor {
    
    var fenceRegion: CLCircularRegion?

    func startRegionMonitoring() {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            log("Couldn't start monitoring because this device does not support it", entryType: .error)
            return
        }
        
        guard let location = ServiceContainer.shared.traceIdService.currentLocationInfo else {
            log("Couldn't start monitoring because the location is not available", entryType: .error)
            return
        }
        
        guard let lat = location.lat,
              let lng = location.lng else {
            log("Couldn't start monitoring because the coordinates are not available", entryType: .error)
            return
        }
        
        let venueLocation = CLLocation(latitude: lat, longitude: lng)
        fenceRegion = CLCircularRegion(center: venueLocation.coordinate, radius: location.radius, identifier: location.groupName ?? "Unknown Venue")
        fenceRegion!.notifyOnExit = true
        
        #if DEBUG
        NotificationScheduler.shared.scheduleNotification(title: "Started region monitoring", message: "")
        #endif
        
        LucaPreferences.shared.autoCheckout = true
        ServiceContainer.shared.locationUpdater.startMonitoring(region: fenceRegion!)
    }
    
    func stopRegionMonitoring() {
        let monitoredRegions = ServiceContainer.shared.locationUpdater.monitoredRegions.map { $0 as? CLCircularRegion }.filter { $0 != nil }.map { $0! }
        
        #if DEBUG
        NotificationScheduler.shared.scheduleNotification(title: "Stopped region monitoring", message: "")
        #endif

        for region in monitoredRegions {
            ServiceContainer.shared.locationUpdater.stopMonitoring(region: region)
        }
    }
    
    func stopRegionMonitoringRx() -> Completable {
        return Completable.from {
            self.stopRegionMonitoring()
        }
    }
    
}

extension RegionMonitor: LogUtil, UnsafeAddress {}
