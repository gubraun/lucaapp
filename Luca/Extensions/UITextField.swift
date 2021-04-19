import UIKit

extension UITextField {
    var textValue: String {
        return text ?? ""
    }

    var isTextEmpty: Bool {
        return textValue == ""
    }
}
