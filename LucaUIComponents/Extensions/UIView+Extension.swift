import Foundation
import UIKit

public extension UIView {
    @objc dynamic var borderColor: UIColor! {
        get { return UIColor(cgColor: layer.borderColor ?? UIColor.clear.cgColor) }
        set {
            layer.borderColor = newValue.cgColor
        }
    }
}
