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

        let serviceContainer = ServiceContainer.shared
        viewController.viewModel = DefaultLocationCheckInViewModel(
            traceInfo: traceInfo,
            traceIdService: serviceContainer.traceIdService,
            timer: CheckinTimer.shared,
            preferences: LucaPreferences.shared,
            autoCheckoutService: serviceContainer.autoCheckoutService,
            notificationService: serviceContainer.notificationService)

        return viewController
    }

    static func createPrivateMeetingViewController(meeting: PrivateMeetingData) -> PrivateMeetingViewController {
        let viewController: PrivateMeetingViewController = PrivateMeetingViewController.fromStoryboard()
        viewController.meeting = meeting
        return viewController
    }

    static func createQRScannerViewController() -> QRScannerViewController {
        return QRScannerViewController()
    }
}
