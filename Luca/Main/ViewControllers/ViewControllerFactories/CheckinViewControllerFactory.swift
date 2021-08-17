import UIKit

class CheckinViewControllerFactory {
    static func createContactQRViewControllerTab() -> UIViewController {
        let contactQRViewController = ContactQRViewController.fromStoryboard()
        let navigationController = UINavigationController(rootViewController: contactQRViewController)
        navigationController.tabBarItem.image = UIImage.init(named: "scanner")
        navigationController.tabBarItem.title = L10n.Navigation.Tab.checkin

        return navigationController
    }

    static func createLocationCheckinViewController(traceInfo: TraceInfo) -> LocationCheckinViewController {
        let viewController: LocationCheckinViewController = LocationCheckinViewController.fromStoryboard()

        let sc = ServiceContainer.shared
        viewController.viewModel = DefaultLocationCheckInViewModel(
            traceInfo: traceInfo,
            traceIdService: sc.traceIdService,
            timer: CheckinTimer.shared,
            preferences: LucaPreferences.shared,
            locationUpdater: sc.locationUpdater,
            locationPermissionHandler: LocationPermissionHandler.shared,
            autoCheckoutService: sc.autoCheckoutService,
            notificationService: sc.notificationService)

        return viewController
    }

    static func createPrivateMeetingViewController(meeting: PrivateMeetingData) -> PrivateMeetingViewController {
        let vc: PrivateMeetingViewController = PrivateMeetingViewController.fromStoryboard()
        vc.meeting = meeting
        return vc
    }

    static func createQRScannerViewController() -> QRScannerViewController {
        return QRScannerViewController()
    }
}
