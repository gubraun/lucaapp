import Foundation
import UIKit

@IBDesignable
public class LightStandardButton: RoundedLucaButton {}

@IBDesignable
public class DarkStandardButton: RoundedLucaButton {
	internal override func borderWidth() -> CGFloat {return 1}
}

public class SelfSizingLabel: UILabel {

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}

	private func setup() {
		self.adjustsFontForContentSizeCategory = true
	}
}

public class Luca14PtLabel: SelfSizingLabel {}
public class Luca14PtBoldLabel: SelfSizingLabel {}
public class Luca20PtBoldLabel: SelfSizingLabel {}
