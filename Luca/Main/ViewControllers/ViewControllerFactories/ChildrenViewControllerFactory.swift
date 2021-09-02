import UIKit

class ChildrenViewControllerFactory {
    static func createChildrenListViewController() -> ChildrenListViewController {
        return ChildrenListViewController.fromStoryboard()
    }

    static func createChildrenCreateViewController(delegate: ChildrenCreateViewControllerDelegate) -> UINavigationController {
        let viewController: ChildrenCreateViewController = ChildrenCreateViewController.fromStoryboard()
        viewController.delegate = delegate

        return UINavigationController(rootViewController: viewController)
    }
}
