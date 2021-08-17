import UIKit

class HistoryViewControllerFactory {
    static func createHistoryViewControllerTab() -> UIViewController {
        let historyViewController = HistoryViewController.fromStoryboard()
        let navigationController = UINavigationController(rootViewController: historyViewController)
        navigationController.tabBarItem.image = UIImage.init(named: "historyActive")
        navigationController.tabBarItem.title = L10n.Navigation.Tab.history

        return navigationController
    }
}
