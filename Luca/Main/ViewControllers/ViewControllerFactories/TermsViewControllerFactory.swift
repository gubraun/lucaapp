import UIKit

class TermsViewControllerFactory {
    static func createTermsAcceptanceViewController() -> UIViewController {
        let termsAcceptanceViewController = TermsAcceptanceViewController()

        return termsAcceptanceViewController
    }
}
