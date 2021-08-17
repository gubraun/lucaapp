import UIKit
import LicensesViewController

public class EditAccountCoordinator: NSObject, Coordinator {

    private let presenter: UIViewController

    public init(presenter: UIViewController) {
        self.presenter = presenter
    }

    public func start() {
        let contactViewController = ViewControllerFactory.Main.createContactViewController()
        presenter.navigationController?.pushViewController(contactViewController, animated: true)
    }
}
