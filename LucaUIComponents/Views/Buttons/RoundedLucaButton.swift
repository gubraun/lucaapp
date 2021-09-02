import Foundation
import UIKit

open class RoundedLucaButton: DesignableButton {
	internal var cornerRad: CGFloat = 24
	internal func borderWidth() -> CGFloat {return 0}

	public override init(frame: CGRect) {
		super.init(frame: frame)
		self.setup()
	}
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.setup()
	}

	open override func prepareForInterfaceBuilder() {
		self.setup()
	}

	func setup() {
		self.cornerRadius = cornerRad
		self.layer.borderWidth = borderWidth()
		self.titleLabel?.numberOfLines = 0
		self.titleLabel?.adjustsFontForContentSizeCategory = true
		self.titleLabel?.lineBreakMode = .byWordWrapping
	}

	override open var intrinsicContentSize: CGSize {
		let labelSize = titleLabel?.sizeThatFits(CGSize(width: frame.width, height: .greatestFiniteMagnitude)) ?? .zero
		let imageWidth = imageView?.frame.width ?? 0 + imageEdgeInsets.top + imageEdgeInsets.bottom
		let imageHeight = imageView?.frame.height ?? 0 + imageEdgeInsets.left + imageEdgeInsets.right
		let desiredButtonSize = CGSize(width: labelSize.width + titleEdgeInsets.left + titleEdgeInsets.right + imageWidth,
																	 height: labelSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom + imageHeight)

		return desiredButtonSize
	}
}
