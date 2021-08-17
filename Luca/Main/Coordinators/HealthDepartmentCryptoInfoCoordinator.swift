import UIKit

public class HealthDepartmentCryptoInfoCoordinator: Coordinator {

    private let presenter: UIViewController

    public init(presenter: UIViewController) {
        self.presenter = presenter
    }

    public func start() {
        let vc = ViewControllerFactory.Main.createHealthDepartmentCryptoInfoViewController()
        presenter.navigationController?.pushViewController(vc, animated: true)
    }
}
