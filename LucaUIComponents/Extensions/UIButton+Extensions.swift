import Foundation
import UIKit

public extension UIButton {
	@objc dynamic var titleLabelFont: UIFont! {
		get { return titleLabel?.font }
		set { titleLabel?.font = newValue }
	}

	@objc dynamic var titleLabelColor: UIColor! {
		get { return titleLabel?.textColor }
		set {
			titleLabel?.textColor = newValue
			setTitleColor(newValue, for: .normal)
		}
	}

	@objc func setTitleLabelColor(color: UIColor, state: UIControl.State) {
		setTitleColor(color, for: state)
	}
}
