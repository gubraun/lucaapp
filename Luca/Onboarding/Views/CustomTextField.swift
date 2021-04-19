import UIKit
import MaterialComponents.MaterialTextFields

class FormTextField: UIView {

    var textFieldController: MDCTextInputControllerOutlined!
    var textField: MDCTextField!
    var type: FormComponentType!
    var isOptional = false

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        textField.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
    }

    init(frame: CGRect, type: FormComponentType, optional: Bool = false) {
        super.init(frame: frame)
        self.isOptional = optional
        self.type = type
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        setupTextFields()

        textField.autocorrectionType = .yes
        textField.textContentType = type.textContentType
        textField.keyboardType = type.keyboardType
        textField.returnKeyType = .next

        set(placeholder: type.placeholder, text: type.value)
    }

    func setupTextFields() {
        textField = MDCTextField(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        textFieldController = MDCTextInputControllerOutlined(textInput: textField)

        textFieldController.activeColor = .lucaWhiteTextFieldBorder
        textFieldController.normalColor = .lucaWhiteTextFieldBorder
        textFieldController.inlinePlaceholderColor = .lucaWhiteTextFieldBorder
        textFieldController.floatingPlaceholderActiveColor = .white
        textFieldController.floatingPlaceholderNormalColor = .white
        textFieldController.borderStrokeColor = .lucaWhiteTextFieldBorder
        textFieldController.inlinePlaceholderFont = UIFont.init(descriptor: UIFontDescriptor(name: "Montserrat-Regular", size: 15), size: 15)

        textFieldController.floatingPlaceholderScale = 0.9
        textField.font = UIFont.init(descriptor: UIFontDescriptor(name: "Montserrat-Regular", size: 15), size: 15)
        textField.textColor = .white

        self.addSubview(textField)
    }

    func setPlaceholder(text: String) {
        if isOptional {
            textField.placeholder = "\(text) (optional)"
        } else {
            textField.placeholder = text
        }
    }

    func setKeyboard(type: UIKeyboardType) {
        textField.keyboardType = type
    }

    func setText(_ text: String?) {
        textField.text = text ?? ""
    }

    func set(placeholder: String, text: String?) {
        setPlaceholder(text: placeholder)
        setText(text)
    }

    func set(_ textContentType: UITextContentType, autocorrection: UITextAutocorrectionType = .default) {
        textField.autocorrectionType = autocorrection
        textField.textContentType = textContentType

        // Few keyboard type helpers (not all though!)
        switch textContentType {
        case .name, .namePrefix, .nameSuffix, .givenName, .middleName, .familyName, .addressCity, .addressState, .addressCityAndState, .streetAddressLine1, .streetAddressLine2, .fullStreetAddress:
            textField.keyboardType = .webSearch
        case .telephoneNumber:
            textField.keyboardType = .phonePad
        case .postalCode:
            textField.keyboardType = .numberPad
        case .emailAddress:
            textField.keyboardType = .emailAddress
        default:
            textField.keyboardType = .default
        }
    }
}
