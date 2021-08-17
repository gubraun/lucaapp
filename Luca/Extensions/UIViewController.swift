import UIKit

extension UIViewController {

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

}

extension UIViewController {
    static var visibleViewController: UIViewController? {
        var currentVc = UIApplication.shared.keyWindow?.rootViewController
        while let presentedVc = currentVc?.presentedViewController {
            if let navVc = (presentedVc as? UINavigationController)?.viewControllers.last {
                currentVc = navVc
            } else if let tabVc = (presentedVc as? UITabBarController)?.selectedViewController {
                currentVc = tabVc
            } else {
                currentVc = presentedVc
            }
        }
        return currentVc
    }
}

extension UIViewController {
    static func instantiate<T: UIViewController>(storyboard: UIStoryboard, identifier: String) -> T {
        let viewController = storyboard.instantiateViewController(withIdentifier: identifier) as? T
        if viewController == nil {
            print("Error instantiating UIViewController. Storyboard is setup incorrectly.")
        }
        // Is purposefully force unwrapped to crash the system if the storyboard is setup incorrectly.
        return viewController!
    }

    static func fromStoryboard<T: UIViewController>() -> T {
        let identifier = String(describing: self)
        let viewController = UIStoryboard(name: identifier, bundle: nil).instantiateViewController(withIdentifier: identifier) as? T
        if viewController == nil {
            print("Error instantiating UIViewController. Storyboard is setup incorrectly.")
        }
        // Is purposefully force unwrapped to crash the system if the storyboard is setup incorrectly.
        return viewController!
    }
}
