import Foundation
import UIKit
import LucaUIComponents

internal struct Styling {
	static func applyStyling() {
		DarkStandardButton.appearance().titleLabelFont = Styling.font(font: FontFamily.Montserrat.bold.font(size: 14))
		DarkStandardButton.appearance().titleLabelColor = UIColor.white
		DarkStandardButton.appearance().backgroundColor = UIColor.clear

		LightStandardButton.appearance().titleLabelFont = Styling.font(font: FontFamily.Montserrat.bold.font(size: 14))
		LightStandardButton.appearance().titleLabelColor = UIColor.black
		LightStandardButton.appearance().backgroundColor = Asset.lucaLightGrey.color
	}

	private static func font(font: UIFont, textStyle: UIFont.TextStyle = UIFont.TextStyle.body, maximumFontSize: CGFloat = 30) -> UIFont {
//			let font = UIFont(name: name, size: size)!
		let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
		return fontMetrics.scaledFont(for: font, maximumPointSize: maximumFontSize)
	}

}
