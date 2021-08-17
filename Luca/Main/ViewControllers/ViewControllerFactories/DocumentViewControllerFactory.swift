import UIKit

class DocumentViewControllerFactory {
    static func createHealthViewControllerTab() -> UIViewController {
        let contactQRViewController = HealthViewController.fromStoryboard()
        let navigationController = UINavigationController(rootViewController: contactQRViewController)
        navigationController.tabBarItem.image = UIImage.init(named: "myLuca")
        navigationController.tabBarItem.title = L10n.Navigation.Tab.health

        return navigationController
    }

    static func createTestQRScannerViewController() -> TestQRCodeScannerController {
        return TestQRCodeScannerController.fromStoryboard()
    }
}
