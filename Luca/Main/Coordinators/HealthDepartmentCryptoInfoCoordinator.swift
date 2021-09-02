import UIKit

public class HealthDepartmentCryptoInfoCoordinator: Coordinator {

    private let presenter: UIViewController

    public init(presenter: UIViewController) {
        self.presenter = presenter
    }

    public func start() {
        let viewController = ViewControllerFactory.Main.createHealthDepartmentCryptoInfoViewController()
        presenter.navigationController?.pushViewController(viewController, animated: true)
    }
}
