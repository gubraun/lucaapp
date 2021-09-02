import UIKit

public class GitlabLinkCoordinator: Coordinator {

    private let url: String
    private let presenter: UIViewController

    public init(presenter: UIViewController, url: String) {
        self.presenter = presenter
        self.url = url
    }

    public func start() {

        let alert = UIAlertController.actionAndCancelAlert(title: L10n.General.Gitlab.Alert.title,
                                                           message: L10n.General.Gitlab.Alert.description,
                                                           actionTitle: L10n.General.Gitlab.Alert.actionButton) {
            guard let url = URL(string: self.url) else {
                return
            }
            UIApplication.shared.open(url, options: [:])
        } cancelAction: {}

        self.presenter.present(alert, animated: true, completion: nil)
    }
}
