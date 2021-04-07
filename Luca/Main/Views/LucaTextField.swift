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
        
        textFieldController.activeColor = .lucaLightGrey
        textFieldController.normalColor = .lucaLightGrey
        textFieldController.inlinePlaceholderColor = .lucaLightGrey
        textFieldController.floatingPlaceholderActiveColor = .lucaLightGrey
        textFieldController.floatingPlaceholderNormalColor = .lucaLightGrey
        textFieldController.borderStrokeColor = .lucaLightGrey
        textField.textColor = .black
    }
    
}
