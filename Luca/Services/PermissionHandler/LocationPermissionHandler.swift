import CoreLocation
import RxSwift

class LocationPermissionHandler: PermissionHandler<CLAuthorizationStatus> {

    public static let shared = LocationPermissionHandler()

    private let currentPermissionPublisher = PublishSubject<State>()
    private var locationManager: CLLocationManager

    override init() {
        if Thread.isMainThread {
            self.locationManager = CLLocationManager()
        } else {
            self.locationManager = DispatchQueue.main.sync { CLLocationManager() }
        }
        super.init()
        self.locationManager.delegate = self
    }

    var alwaysAlreadyAsked: Bool {
        get {
            UserDefaults.standard.bool(forKey: "alwaysAlreadyAsked")
        } set {
            UserDefaults.standard.setValue(newValue, forKey: "alwaysAlreadyAsked")
        }
    }

    override var currentPermission: State {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    private var currentPermissionMaybe: Maybe<State> {
        Maybe.from { [weak self] in
            return self?.currentPermission
        }
    }

    override var permissionChanges: Observable<State> {
        Observable.merge(currentPermissionMaybe.asObservable(),
                         currentPermissionPublisher.asObservable())
    }

    // For iOS 13.0+ there is an issue:
    // If I request while in use, use has three possibilites:
    // A - Allow when in use
    // B - Allow once
    // C - Deny
    // If User takes the A and I request for always, the prompt will show up
    // If User takes the B and I request for always, there won't be any prompt. I would have to wait till the app is backgrounded and brought back again
    //
    // To be able to handle all cases, I have to simplify the logic and prevent double popups. So, if the current state is not .notDetermined, there will be an error thrown

    /// Requests location permission. Emits error if there was a request already issued. Succeeds if the request has been sent successfully.
    override func request(_ permission: State) -> Completable {
        Completable.from { [weak self] in
            guard let s = self else {
                throw PermissionHandlerError.unknown
            }

            if s.currentPermission == .notDetermined {
                s.alwaysAlreadyAsked = false
            }
            if permission != .authorizedAlways && permission != .authorizedWhenInUse {
                throw PermissionHandlerError.invalidRequest
            }

            // For iOS 13.0+: There can be only one request issued because of the leaky logic
            // For iOS below 13.0: After whenInUse is granted, there can be one always request issued.
            if #available(iOS 13.0, *) {
                if s.currentPermission != .notDetermined {
                    throw PermissionHandlerError.cannotBeRequestedAnymore
                }
                if permission == .authorizedAlways {
                    s.locationManager.requestAlwaysAuthorization()
                } else {
                    s.locationManager.requestWhenInUseAuthorization()
                }
            } else {
                if permission == .authorizedWhenInUse {
                    if s.currentPermission != .notDetermined {
                        throw PermissionHandlerError.cannotBeRequestedAnymore
                    } else {
                        s.locationManager.requestWhenInUseAuthorization()
                    }
                } else {
                    let canBeAskedForAlways = (s.currentPermission == .authorizedWhenInUse && !s.alwaysAlreadyAsked) ||
                        s.currentPermission == .notDetermined
                    if canBeAskedForAlways {
                        s.alwaysAlreadyAsked = true
                        s.locationManager.requestAlwaysAuthorization()
                    } else {
                        throw PermissionHandlerError.cannotBeRequestedAnymore
                    }
                }
            }
        }
    }
}

extension LocationPermissionHandler: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.currentPermissionPublisher.onNext(self.currentPermission)
    }
}
