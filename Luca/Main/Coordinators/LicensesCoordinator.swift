import UIKit
import LicensesViewController

public class LicensesCoordinator: NSObject, Coordinator {

    private let presenter: UIViewController

    public init(presenter: UIViewController) {
        self.presenter = presenter
    }

    public func start() {
        let licensesViewController = LicensesViewController()
        licensesViewController.loadPlist(Bundle.main, resourceName: "Credits")
        presenter.navigationController?.pushViewController(licensesViewController, animated: true)
    }
}
