import UIKit

public class VersionDetailsCoordinator: Coordinator {

    private let presenter: UIViewController

    public init(presenter: UIViewController) {
        self.presenter = presenter
    }

    public func start() {
        let vc = AlertViewControllerFactory.createAppVersionAlertController()
        presenter.present(vc, animated: true, completion: nil)
    }
}
