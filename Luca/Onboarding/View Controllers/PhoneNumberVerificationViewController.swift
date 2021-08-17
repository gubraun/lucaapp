import UIKit
import JGProgressHUD
import PhoneNumberKit

class PhoneNumberVerificationViewController: UIViewController {

    @IBOutlet weak var verificationTextField: LucaTextField!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var noTANButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    var challengeIds: [String] = []

    var loadingHud = JGProgressHUD.lucaLoading()

    var onUserCanceled: (() -> Void)?

    /// Callback with the matching challenge
    var onSuccess: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        verificationTextField.textField.delegate = self
        enableVerifyButton(false)

        setupTANTextField()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAccessibility()
    }

    @IBAction func confirmButtonPressed(_ sender: UIButton) {
        DispatchQueue.main.async { self.loadingHud.show(in: self.view) }

        if let tanText = verificationTextField.textField.text {
            ServiceContainer.shared.backendSMSV3.verify(tan: tanText, challenges: challengeIds)
                .execute { matchedChallenge in
                    DispatchQueue.main.async { self.loadingHud.dismiss() }
                    self.onSuccess?(matchedChallenge)
                } failure: { (error) in
                    DispatchQueue.main.async { self.loadingHud.dismiss() }
                    self.showAlert(title: L10n.Navigation.Basic.error, message: error.localizedDescription, onOk: nil)
                }
        }
    }

    func showAlert(title: String, message: String, onOk: (() -> Void)? = nil) {
        DispatchQueue.main.async {

            let alert = ViewControllerFactory.Alert.createAlertViewController(
                title: title,
                message: message,
                firstButtonTitle: L10n.Navigation.Basic.ok.uppercased()) {
                onOk?()
            }
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func showInfo(_ sender: UIButton) {

        let alert = ViewControllerFactory.Alert.createAlertViewController(
            title: L10n.Verification.PhoneNumber.Info.title,
            message: L10n.Verification.PhoneNumber.Info.message,
            firstButtonTitle: L10n.Navigation.Basic.ok.uppercased())
        present(alert, animated: true, completion: nil)
    }

    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        self.onUserCanceled?()
    }

    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    func setupTANTextField() {
        verificationTextField.setPlaceholder(text: L10n.Verification.PhoneNumber.code)
        verificationTextField.setupGreyField()
    }

    func enableVerifyButton(_ enabled: Bool) {
        verifyButton.isEnabled = enabled
    }

}
extension PhoneNumberVerificationViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        if verificationTextField.textField.text != nil && verificationTextField.textField.text?.count == 6 {
            enableVerifyButton(true)
        } else {
            enableVerifyButton(false)
        }
    }

}

// MARK: - Accessibility
extension PhoneNumberVerificationViewController {

    private func setupAccessibility() {
        self.view.accessibilityElements = [titleLabel, descriptionLabel, verificationTextField, noTANButton, verifyButton, cancelButton].map { $0 as Any }
        titleLabel.accessibilityTraits = .header
        UIAccessibility.setFocusTo(titleLabel, notification: .screenChanged, delay: 0.8)
    }

}
