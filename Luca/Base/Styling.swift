import Foundation
import UIKit
import LucaUIComponents

internal struct Styling {
	static func applyStyling() {
		// navigation bar
		let attrsTitle = [NSAttributedString.Key.font: FontFamily.Montserrat.bold.font(size: 20), NSAttributedString.Key.foregroundColor: UIColor.white]
		UINavigationBar.appearance().titleTextAttributes = attrsTitle
		UINavigationBar.appearance().barTintColor = UIColor.black
		UINavigationBar.appearance().tintColor = UIColor.white
		UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().shadowImage = UIImage()

		let attrsButton = [
			NSAttributedString.Key.font: FontFamily.Montserrat.bold.font(size: 14),
			NSAttributedString.Key.foregroundColor: UIColor.white
		]
		UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes(attrsButton, for: .normal)
		UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes(attrsButton, for: .highlighted)

		DarkStandardButton.appearance().titleLabelFont = Styling.font(font: FontFamily.Montserrat.bold.font(size: 14))
		DarkStandardButton.appearance().titleLabelColor = UIColor.white
		DarkStandardButton.appearance().backgroundColor = UIColor.clear
		DarkStandardButton.appearance().borderColor = UIColor.white

		LightStandardButton.appearance().titleLabelFont = Styling.font(font: FontFamily.Montserrat.bold.font(size: 14))
		LightStandardButton.appearance().titleLabelColor = UIColor.black
		LightStandardButton.appearance().backgroundColor = Asset.lucaBlue.color

        LucaDefaultTextField.appearance().backgroundColor = .clear
        LucaDefaultTextField.appearance().font = FontFamily.Montserrat.medium.font(size: 14)
        LucaDefaultTextField.appearance().borderColor = Asset.luca747480.color

		Luca14PtLabel.appearance().font = Styling.font(font: FontFamily.Montserrat.medium.font(size: 14))
		Luca14PtLabel.appearance().textColor = UIColor.white

		Luca14PtBoldLabel.appearance().font = Styling.font(font: FontFamily.Montserrat.bold.font(size: 14))
		Luca14PtBoldLabel.appearance().textColor = UIColor.white

        Luca20PtBoldLabel.appearance().font = Styling.font(font: FontFamily.Montserrat.bold.font(size: 20))
        Luca20PtBoldLabel.appearance().textColor = UIColor.white
}

	private static func font(font: UIFont, textStyle: UIFont.TextStyle = UIFont.TextStyle.body, maximumFontSize: CGFloat = 30) -> UIFont {
		let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
		return fontMetrics.scaledFont(for: font, maximumPointSize: maximumFontSize)
	}

}

protocol LucaModalAppearence {
	func applyColors()
}

extension LucaModalAppearence where Self: UIViewController {
	func applyColors() {
		self.navigationController?.navigationBar.barTintColor = Asset.luca1d1d1d.color
        self.navigationController?.navigationBar.shadowImage = UIImage()

		self.view.backgroundColor = Asset.luca1d1d1d.color
		let attrsButton = [
			NSAttributedString.Key.font: FontFamily.Montserrat.bold.font(size: 14),
			NSAttributedString.Key.foregroundColor: Asset.lucaBlue.color
		]

		self.navigationItem.rightBarButtonItem?.setTitleTextAttributes(attrsButton, for: .normal)
		self.navigationItem.rightBarButtonItem?.setTitleTextAttributes(attrsButton, for: .highlighted)
		self.navigationItem.leftBarButtonItem?.setTitleTextAttributes(attrsButton, for: .normal)
		self.navigationItem.leftBarButtonItem?.setTitleTextAttributes(attrsButton, for: .highlighted)
	}
}
