import Foundation
import UIKit

@IBDesignable
open class DesignableButton: UIButton {
	@IBInspectable
	public var cornerRadius: CGFloat {
		get {
			return layer.cornerRadius
		}
		set {
			layer.cornerRadius = newValue
		}
	}

	@IBInspectable
	var adjustsFontForContentSizeCategory: Bool {
			get {
                return self.titleLabel?.adjustsFontForContentSizeCategory ?? false
			}
			set {
                self.titleLabel?.adjustsFontForContentSizeCategory = newValue
			}
	}
}
