import UIKit

extension UIAccessibility {

    static func setFocusTo(_ object: Any?, notification: UIAccessibility.Notification, delay: Double = 0.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(notification: notification, argument: object)
        }
    }

}
