import UIKit
import MaterialComponents.MaterialTextFields

class FormView: UIView {

    private var types: [FormComponentType] = []
    private var requirements: [Bool] = []
    private(set) var textFields = [FormTextField]()

    var textFieldsFilledOut: Bool {
        if requirements.count == 0 {
            return !textFields.map { $0.textField.text == "" }.contains(true)
        }
        return !textFields
            .enumerated()
            .filter { requirements[$0.offset] }
            .contains(where: { $0.element.textField.text == nil || $0.element.textField.text == "" })
    }

    func setup(step: OnboardingStep) {
        self.types = step.formComponents
        self.requirements = step.requirements
        if !requirements.isEmpty && requirements.count != types.count {
            log("Types and requirements count should be the same!", entryType: .error)
            return
        }
        textFields = []
        for view in subviews {
            view.removeFromSuperview()
        }

        let stackView = setupStackView()

        if let info = step.additionalInfo {
            let label = setupAdditionalInfoLabel(info: info)
            stackView.addArrangedSubview(label)
            label.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        }

        for index in 0..<types.count {
            let isOptional = requirements.isEmpty ? false : !requirements[index]
            let textField = FormTextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                            type: types[index],
                                            optional: isOptional)

            textField.tag = index
            textField.set(types[index].textContentType, autocorrection: .yes)
            textFields.append(textField)

            stackView.addArrangedSubview(textField)
            textField.heightAnchor.constraint(equalToConstant: 75).isActive = true
            textField.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
            textField.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        }
        self.addSubview(stackView)

        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupAdditionalInfoLabel(info: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.textColor = .white
        label.font = UIFont.init(descriptor: UIFontDescriptor(name: "Montserrat-Regular", size: 13), size: 13)
        label.text = info
        label.sizeToFit()
        return label
    }

    func setupStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 10
        return stackView
    }

    func showErrorStatesForEmptyFields() {
        var errorAccessibilityValue: String?
        if requirements.count == textFields.count {
            for (index, field) in textFields.enumerated() {
                if field.textField.text == "" && requirements[index] {
                    errorAccessibilityValue = types[index].accessibilityError
                    field.textFieldController.setErrorText("", errorAccessibilityValue: "")
                }
            }
        } else {
            for (index, field) in textFields.enumerated() where field.textField.text == "" {
                errorAccessibilityValue = types[index].accessibilityError
                field.textFieldController.setErrorText("", errorAccessibilityValue: "")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .announcement, argument: errorAccessibilityValue)
        }
    }

    func showNormalStatesForEmptyFields() {
        for field in textFields {
            field.textFieldController.setErrorText(nil, errorAccessibilityValue: "")
        }
    }

}

extension FormView: UnsafeAddress, LogUtil {}
