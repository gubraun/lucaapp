import UIKit

extension UIFont {

    static var montserratRegularTimer: UIFont {
        // Italic font as an alternative so that we know something is broken.
        UIFont(name: "Montserrat-Regular", size: 50.0) ?? UIFont.italicSystemFont(ofSize: 60.0)
    }

    static var montserratCheckbox: UIFont {
        UIFont(name: "Montserrat-Medium", size: 12.0) ?? UIFont.italicSystemFont(ofSize: 12.0)
    }

    static var montserratTableViewTitle: UIFont {
        UIFont(name: "Montserrat-Bold", size: 16.0) ?? UIFont.italicSystemFont(ofSize: 16.0)
    }

    static var montserratTableViewDescription: UIFont {
        UIFont(name: "Montserrat-Medium", size: 14.0) ?? UIFont.italicSystemFont(ofSize: 14.0)
    }

    static var montserratDataAccessAlertDescriptionBold: UIFont {
        UIFont(name: "Montserrat-Bold", size: 14.0) ?? UIFont.italicSystemFont(ofSize: 14.0)
    }

    static var montserratDataAccessAlertDescription: UIFont {
        UIFont(name: "Montserrat-Medium", size: 14.0) ?? UIFont.italicSystemFont(ofSize: 14.0)
    }

    static var montserratDataAccessAlertDayPicker: UIFont {
        UIFont(name: "Montserrat-Medium", size: 20) ?? UIFont.italicSystemFont(ofSize: 20)
    }

    static var montserratViewControllerTitle: UIFont {
        UIFont(name: "Montserrat-Bold", size: 20.0) ?? UIFont.italicSystemFont(ofSize: 20.0)
    }

    static var oggViewControllerTitle: UIFont {
        UIFont(name: "Ogg-Regular", size: 48.0) ?? UIFont.italicSystemFont(ofSize: 48.0)
    }
}

extension UIFont {

    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {

        // create a new font descriptor with the given traits
        guard let fd = fontDescriptor.withSymbolicTraits(traits) else {
            // the given traits couldn't be applied, return self
            return self
        }

        // return a new font with the created font descriptor
        return UIFont(descriptor: fd, size: pointSize)
    }

    func italics() -> UIFont {
        return withTraits(.traitItalic)
    }

    func bold() -> UIFont {
        return withTraits(.traitBold)
    }

    func boldItalics() -> UIFont {
        return withTraits([ .traitBold, .traitItalic ])
    }
}
