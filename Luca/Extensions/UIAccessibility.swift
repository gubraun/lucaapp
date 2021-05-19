import UIKit

extension UIAccessibility {

    static func setFocusTo(_ object: Any?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            UIAccessibility.post(notification: .screenChanged, argument: object)
        }
    }

    static func setFocusLayout(_ object: Any?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            UIAccessibility.post(notification: .layoutChanged, argument: object)
        }
    }

    static func setFocusLayoutWithDelay(_ object: Any?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            UIAccessibility.post(notification: .layoutChanged, argument: object)
        }
    }

}
