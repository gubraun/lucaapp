import UIKit

class MainViewControllerFactory {
    static func createTabBarController() -> MainTabBarViewController {
        let mainTabBarController = MainTabBarViewController()

        mainTabBarController.viewControllers = [ViewControllerFactory.Checkin.createContactQRViewControllerTab(),
                                                ViewControllerFactory.Document.createHealthViewControllerTab(),
                                                ViewControllerFactory.History.createHistoryViewControllerTab(),
                                                ViewControllerFactory.Account.createAccountViewControllerTab()]
        return mainTabBarController
    }

    static func createContactViewController() -> ContactViewController {
        return ContactViewController.fromStoryboard()
    }

    static func createDataAccessViewController() -> DataAccessViewController {
        return DataAccessViewController.fromStoryboard()
    }

    static func createHealthDepartmentCryptoInfoViewController() -> UIViewController {
        return HealthDepartmentCryptoInfoViewController.fromStoryboard()
    }
}
