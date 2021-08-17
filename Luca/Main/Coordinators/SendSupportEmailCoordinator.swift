import UIKit
import DeviceKit
import MessageUI

public class SendSupportEmailCoordinator: NSObject, Coordinator {

    private let presenter: UIViewController

    public init(presenter: UIViewController) {
        self.presenter = presenter
    }

    public func start() {

        if MFMailComposeViewController.canSendMail() {
            let version = UIApplication.shared.applicationVersion ?? ""
            let messageBody = L10n.General.Support.Email.body(Device.current.description, UIDevice.current.systemVersion, version)

            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([L10n.General.Support.email])
            mail.setMessageBody(messageBody, isHTML: true)
            presenter.present(mail, animated: true)
        } else {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.General.Support.error)
            presenter.present(alert, animated: true, completion: nil)
        }
    }
}

 extension SendSupportEmailCoordinator: MFMailComposeViewControllerDelegate {

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }

 }
