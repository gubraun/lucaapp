import UIKit

extension UIAccessibility {
    static func setFocusTo(_ object: Any?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            UIAccessibility.post(notification: .screenChanged, argument: object)
        }
    }
}
