import UIKit

class AccountViewControllerFactory {
    static func createAccountViewControllerTab() -> UIViewController {
        let accountViewController = AccountViewController()
        let navigationController = UINavigationController(rootViewController: accountViewController)
        navigationController.tabBarItem.image = UIImage.init(named: "accountActive")
        navigationController.tabBarItem.title = L10n.Navigation.Tab.account

        return navigationController
    }
}
