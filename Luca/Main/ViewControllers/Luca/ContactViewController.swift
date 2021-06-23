import UIKit
import JGProgressHUD

class ContactViewController: UIViewController {

    @IBOutlet weak var firstNameTextField: LucaTextField!
    @IBOutlet weak var lastNameTextField: LucaTextField!
    @IBOutlet weak var emailTextField: LucaTextField!
    @IBOutlet weak var addressStreetTextField: LucaTextField!
    @IBOutlet weak var addressHouseNumberTextField: LucaTextField!
    @IBOutlet weak var addressPostCodeTextField: LucaTextField!
    @IBOutlet weak var addressCityTextField: LucaTextField!
    @IBOutlet weak var phoneNumberTextField: LucaTextField!

    private var progressHud = JGProgressHUD.lucaLoading()

    private var saveButton: UIBarButtonItem!
    var phoneNumberVerificationService: PhoneNumberVerificationService?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.saveButton = UIBarButtonItem(title: L10n.ContactViewController.save, style: .done, target: self, action: #selector(onSaveButton(_:)))

        firstNameTextField.textField.delegate = self
        firstNameTextField.set(.givenName)

        lastNameTextField.textField.delegate = self
        lastNameTextField.set(.familyName)

        emailTextField.textField.delegate = self
        emailTextField.set(.emailAddress)

        addressStreetTextField.textField.delegate = self
        addressStreetTextField.set(.streetAddressLine1)

        addressHouseNumberTextField.textField.delegate = self
        addressHouseNumberTextField.set(.streetAddressLine2)

        addressPostCodeTextField.textField.delegate = self
        addressPostCodeTextField.set(.postalCode)

        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.set(.telephoneNumber)

        addressCityTextField.textField.delegate = self
        addressCityTextField.set(.addressCity)

        if !LucaPreferences.shared.phoneNumberVerified {
            self.navigationItem.rightBarButtonItem = self.saveButton
        }
    }

    func setupViews() {
        firstNameTextField.set(placeholder: L10n.UserData.Form.firstName, text: LucaPreferences.shared.firstName)
        lastNameTextField.set(placeholder: L10n.UserData.Form.lastName, text: LucaPreferences.shared.lastName)
        emailTextField.set(placeholder: L10n.UserData.Form.email, text: LucaPreferences.shared.emailAddress)
        addressStreetTextField.set(placeholder: L10n.UserData.Form.street, text: LucaPreferences.shared.street)
        addressHouseNumberTextField.set(placeholder: L10n.UserData.Form.houseNumber, text: LucaPreferences.shared.houseNumber)
        addressPostCodeTextField.set(placeholder: L10n.UserData.Form.postCode, text: LucaPreferences.shared.postCode)
        addressCityTextField.set(placeholder: L10n.UserData.Form.city, text: LucaPreferences.shared.city)
        phoneNumberTextField.set(placeholder: L10n.UserData.Form.phoneNumber, text: LucaPreferences.shared.phoneNumber)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setTranslucent()
        self.navigationController?.navigationBar.tintColor = .white
        setupViews()
    }

    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    @IBAction func onSaveButton(_ sender: UIBarButtonItem) {

        self.hideKeyboard()

        if !dataValidation() {
            return
        }

        let alert = UIAlertController.yesOrNo(title: L10n.ContactViewController.ShouldSave.title, message: L10n.ContactViewController.ShouldSave.message, onYes: {
            self.verifyPhoneNumber(completion: { success in
                if success {
                    self.save { success in
                        if success {
                            self.navigationItem.rightBarButtonItem = nil
                        }
                    }
                }
            })
        })
        self.present(alert, animated: true, completion: nil)
    }

    func verifyPhoneNumber(completion: @escaping(Bool) -> Void) {
        if self.phoneNumberTextField.textField.text != LucaPreferences.shared.phoneNumber || !LucaPreferences.shared.phoneNumberVerified,
           let phoneNumber = self.phoneNumberTextField.textField.text {

            phoneNumberVerificationService = PhoneNumberVerificationService(
                presenting: self.tabBarController ?? self,
                backend: ServiceContainer.shared.backendSMSV3,
                preferences: LucaPreferences.shared)

            phoneNumberVerificationService!.verify(phoneNumber: phoneNumber) { success in
                if success {
                    completion(true)
                    return
                }
                let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Verification.PhoneNumber.updateFailure) {
                    completion(false)
                }
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            completion(true)
        }
    }

    private func save(completion: @escaping (Bool) -> Void) {
        let preferences = LucaPreferences.shared

        preferences.firstName = self.firstNameTextField.textField.text?.sanitize()
        preferences.lastName = self.lastNameTextField.textField.text?.sanitize()
        preferences.street = self.addressStreetTextField.textField.text?.sanitize()
        preferences.houseNumber = self.addressHouseNumberTextField.textField.text?.sanitize()
        preferences.postCode = self.addressPostCodeTextField.textField.text?.sanitize()
        preferences.city = self.addressCityTextField.textField.text?.sanitize()
        preferences.phoneNumber = self.phoneNumberTextField.textField.text?.sanitize()
        preferences.emailAddress = self.emailTextField.textField.text?.sanitize()

        guard preferences.userRegistrationData != nil else {
            log("Save: User Data couldn't be retrieved", entryType: .error)
            return
        }

        guard preferences.uuid != nil else {
            log("Save: User Id couldn't be retrieved!", entryType: .error)
            return
        }

        progressHud.show(in: self.view)
        ServiceContainer.shared.userService.uploadCurrentData {
            DispatchQueue.main.async {
                self.progressHud.dismiss()
                completion(true)
            }
        } failure: { (error) in
            DispatchQueue.main.async {
                self.progressHud.dismiss()
                let errorAlert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.ContactViewController.SaveFailed.message(error.localizedDescription))
                self.present(errorAlert, animated: true, completion: nil)
                completion(false)
            }
        }
    }

    private func dataValidation() -> Bool {
        // Validate form data
        let emptyAddress =  addressCityTextField.textField.isTextEmpty ||
                            addressHouseNumberTextField.textField.isTextEmpty ||
                            addressStreetTextField.textField.isTextEmpty ||
                            addressPostCodeTextField.textField.isTextEmpty

        let emptyRest = firstNameTextField.textField.isTextEmpty ||
            lastNameTextField.textField.isTextEmpty ||
            phoneNumberTextField.textField.isTextEmpty

        if emptyAddress {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.ContactViewController.EmptyAddress.message)
            present(alert, animated: true, completion: nil)
            return false
        }

        if emptyRest {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.ContactViewController.EmptyRest.message)
            present(alert, animated: true, completion: nil)
            return false
        }
        return true
    }

}

extension ContactViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if self.navigationItem.rightBarButtonItem != self.saveButton {
            self.navigationItem.rightBarButtonItem = self.saveButton
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }

}

extension ContactViewController: UnsafeAddress, LogUtil {}
