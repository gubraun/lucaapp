import UIKit

class OnboardingViewControllerFactory {

    private static var storyboard = UIStoryboard(name: "Onboarding", bundle: nil)

    static func instantiateViewController<T: UIViewController>(identifier: String) -> T {
        UIViewController.instantiate(storyboard: storyboard, identifier: identifier)
    }

    static func createFormViewController() -> UIViewController {
        return storyboard.instantiateViewController(withIdentifier: "FormViewController")
    }

    static func createWelcomeViewController() -> UIViewController {
        return storyboard.instantiateViewController(withIdentifier: "WelcomeViewController")
    }

    static func createDataPrivacyViewController() -> UIViewController {
        return storyboard.instantiateViewController(withIdentifier: "DataPrivacyViewController")
    }

    static func createDoneViewController() -> UIViewController {
        return storyboard.instantiateViewController(withIdentifier: "DoneViewController")
    }

    static func createWebViewController(url: URL) -> WebViewController {
        let vc: WebViewController = instantiateViewController(identifier: "WebViewController")
        vc.url = url
        return vc
    }
}
