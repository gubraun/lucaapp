import UIKit
import MaterialComponents.MaterialTextFields

class LucaTextField: FormTextField {

    override func setup() {
        setupTextFields()
    }

    override func setText(_ text: String?) {
        if let value = text, value != "" {
            textFieldController.setErrorText(nil, errorAccessibilityValue: nil)
            textField.text = value
            return
        }
    }

    func setupGreyField() {
        textField.keyboardType = .numberPad

        textFieldController.activeColor = .black
        textFieldController.normalColor = .black
        textFieldController.inlinePlaceholderColor = .black
        textFieldController.floatingPlaceholderActiveColor = .black
        textFieldController.floatingPlaceholderNormalColor = .black
        textFieldController.borderStrokeColor = .black
        textField.textColor = .black
    }

}
