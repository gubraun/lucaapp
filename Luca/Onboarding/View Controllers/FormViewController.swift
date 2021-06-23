import UIKit
import MaterialComponents.MaterialTextFields
import JGProgressHUD

class FormViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var formView: FormView!
    @IBOutlet weak var progressBar: UIProgressView!

    private var progressHud = JGProgressHUD.lucaLoading()
    var phoneNumberVerificationService: PhoneNumberVerificationService?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadViews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        nextButton.layer.cornerRadius = nextButton.frame.size.height / 2
        for field in formView.textFields {
            var fieldFrame = field.frame
            fieldFrame.size.width = formView.frame.size.width
            field.frame = fieldFrame
        }
    }

    func reloadViews() {
        let step = OnboardingStep(rawValue: LucaPreferences.shared.currentOnboardingPage ?? 0)!
        formView.setup(step: step)
        _ = formView.textFields.map { $0.textField.delegate = self }
        nextButton.setTitle(step.buttonTitle, for: .normal)
        titleLabel.text = step.formTitle
        progressBar.progress = step.progress
    }

    @IBAction func nextButtonPressed(_ sender: UIButton) {
        showNextPage()
    }

    @IBAction func rightSwiped(_ sender: UISwipeGestureRecognizer) {
        showPreviousPage()
    }

    @IBAction func leftSwiped(_ sender: UISwipeGestureRecognizer) {
        showNextPage()
    }

    func showNextPage() {
        self.hideKeyboard()
        guard let page = LucaPreferences.shared.currentOnboardingPage,
              let pageEnum = OnboardingStep(rawValue: page) else {
            print("No eligible current page!")
            return
        }
        if formView.textFieldsFilledOut {
            UIAccessibility.setFocusTo(titleLabel)
            print("Current page: \(pageEnum) \(String(describing: LucaPreferences.shared.emailAddress))")
            if pageEnum == .phoneNumber {
                if LucaPreferences.shared.phoneNumberVerified {
                    LucaPreferences.shared.currentOnboardingPage = page + 1
                    reloadViews()
                } else {
                    verifyPhoneNumber()
                }
            } else if page + 1 <= 2 {
                LucaPreferences.shared.currentOnboardingPage = page + 1
                reloadViews()
            } else {
                registerUser()
            }
        } else {
            formView.showErrorStatesForEmptyFields()
        }

    }

    func verifyPhoneNumber() {
        phoneNumberVerificationService = PhoneNumberVerificationService(
            presenting: self,
            backend: ServiceContainer.shared.backendSMSV3,
            preferences: LucaPreferences.shared)

        guard let phoneNumber = LucaPreferences.shared.phoneNumber else {
            return
        }
        phoneNumberVerificationService!.verify(phoneNumber: phoneNumber) { success in
            DispatchQueue.main.async {
                if success {
                    self.showNextPage()
                } else {
                    let alert = UIAlertController.infoAlert(title: L10n.FormViewController.PhoneVerificationFailure.title,
                                                            message: L10n.FormViewController.PhoneVerificationFailure.message)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    func showPreviousPage() {
        if let page = LucaPreferences.shared.currentOnboardingPage, page - 1 >= 0 {
            LucaPreferences.shared.currentOnboardingPage = page - 1
            reloadViews()
        }
    }

    func registerUser() {
        guard LucaPreferences.shared.userRegistrationData != nil else {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error,
                                                    message: L10n.FormViewController.UserDataFailure.Unavailable.message)
            self.present(alert, animated: true, completion: nil)
            return
        }

        progressBar.progress = 1.0
        progressHud.show(in: self.view)
        ServiceContainer.shared.userService.registerIfNeeded { (_) in
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
                self.progressHud.dismiss()
            }
        } failure: { (error) in
            DispatchQueue.main.async {
                self.progressHud.dismiss()
                let alert = UIAlertController.infoAlert(
                    title: L10n.Navigation.Basic.error,
                    message: L10n.FormViewController.UserDataFailure.Failed.message(error.localizedDescription))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

}
extension FormViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        formView.showNormalStatesForEmptyFields()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {

        guard let formTextField = self.formView.textFields.first(where: { $0.textField == textField }),
              let type = formTextField.type else {
            return
        }
        switch type {
        case .firstName:    LucaPreferences.shared.firstName = textField.text?.sanitize()
        case .lastName:     LucaPreferences.shared.lastName = textField.text?.sanitize()
        case .street:       LucaPreferences.shared.street = textField.text?.sanitize()
        case .houseNumber:  LucaPreferences.shared.houseNumber = textField.text?.sanitize()
        case .postCode:     LucaPreferences.shared.postCode = textField.text?.sanitize()
        case .city:         LucaPreferences.shared.city = textField.text?.sanitize()
        case .phoneNumber:
            LucaPreferences.shared.phoneNumber = textField.text?.sanitize()
            LucaPreferences.shared.phoneNumberVerified = false
        case .email:        LucaPreferences.shared.emailAddress = textField.text?.sanitize()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var tag = 0
        // Find first responder manually, since textField returns a tag of 0 for every textfield since we use FormTextField
        for view in formView.textFields where view.textField.isFirstResponder {
            tag = view.tag
        }

        if tag == formView.textFields.count - 1 {
            showNextPage()
        } else if let nextField = view.superview?.viewWithTag(textField.tag + 1) as? FormTextField {
            nextField.textField.becomeFirstResponder()
        }
        return false
    }

}
