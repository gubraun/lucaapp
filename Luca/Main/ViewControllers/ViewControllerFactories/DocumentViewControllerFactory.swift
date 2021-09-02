import UIKit

class DocumentViewControllerFactory {
    static func createHealthViewControllerTab() -> UIViewController {
        let documentViewController = DocumentViewController.fromStoryboard()
        let navigationController = UINavigationController(rootViewController: documentViewController)
        navigationController.tabBarItem.image = UIImage.init(named: "myLuca")
        navigationController.tabBarItem.title = L10n.Navigation.Tab.health

        return navigationController
    }

    static func createTestQRScannerViewController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: TestQRCodeScannerController.fromStoryboard())
        return navigationController
    }
}
