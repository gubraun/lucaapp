import UIKit
import JGProgressHUD
import RxSwift

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

    var currentData: UserRegistrationData! = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup navigationbar title
        title = L10n.UserData.Navigation.title
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont.montserratViewControllerTitle,
                                                                        NSAttributedString.Key.foregroundColor: UIColor.white]

        saveButton = UIBarButtonItem(title: L10n.ContactViewController.save, style: .done, target: self, action: #selector(onSaveButton(_:)))

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
            navigationItem.rightBarButtonItem = self.saveButton
        }
    }

    func setupViews() {
        firstNameTextField.set(placeholder: L10n.UserData.Form.firstName, text: currentData.firstName)
        lastNameTextField.set(placeholder: L10n.UserData.Form.lastName, text: currentData.lastName)
        emailTextField.set(placeholder: L10n.UserData.Form.email, text: currentData.email)
        addressStreetTextField.set(placeholder: L10n.UserData.Form.street, text: currentData.street)
        addressHouseNumberTextField.set(placeholder: L10n.UserData.Form.houseNumber, text: currentData.houseNumber)
        addressPostCodeTextField.set(placeholder: L10n.UserData.Form.postCode, text: currentData.postCode)
        addressCityTextField.set(placeholder: L10n.UserData.Form.city, text: currentData.city)
        phoneNumberTextField.set(placeholder: L10n.UserData.Form.phoneNumber, text: currentData.phoneNumber)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let copiedData = LucaPreferences.shared.userRegistrationData?.copy() as? UserRegistrationData else {

            // It doesn't have to be localized. This error should never happen.
            // This check is there only to get rid of the optionals and data is always there after user has been registered.
            let alert = UIAlertController.infoAlert(title: "Error", message: "Local data is corrupted")
            self.present(alert, animated: true, completion: nil)
            return
        }
        currentData = copiedData
        setupAccessibility()
        setupViews()

        // Hide save button as the data are resetted to the last saved values
        self.navigationItem.rightBarButtonItem = nil
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

            _ = self.verifyPhoneNumber()
                .andThen(self.save()).do(onSubscribe: { DispatchQueue.main.async { self.progressHud.show(in: self.view) } })
                .andThen(Completable.from { self.navigationItem.rightBarButtonItem = nil }.subscribe(on: MainScheduler.instance))
                .andThen(ServiceContainer.shared.documentProcessingService.revalidateSavedTests())
                .do(onError: { [weak self] error in
                    DispatchQueue.main.async {
                        let errorAlert: UIViewController
                        if let localizedError = error as? LocalizedTitledError {
                            errorAlert = UIAlertController.infoAlert(
                                title: localizedError.localizedTitle,
                                message: localizedError.localizedDescription)
                        } else {
                            errorAlert = UIAlertController.infoAlert(
                                title: L10n.Navigation.Basic.error,
                                message: error.localizedDescription)
                        }
                        self?.present(errorAlert, animated: true, completion: nil)
                    }
                })
                .do(onDispose: {
                    DispatchQueue.main.async { self.progressHud.dismiss() }
                })
                .subscribe()
        })
        self.present(alert, animated: true, completion: nil)
    }

    func verifyPhoneNumber() -> Completable {
        if self.phoneNumberTextField.textField.text != currentData.phoneNumber || !LucaPreferences.shared.phoneNumberVerified,
           let phoneNumber = self.phoneNumberTextField.textField.text {

            return Completable.create { observer in

                self.phoneNumberVerificationService = PhoneNumberVerificationService(
                    presenting: self.tabBarController ?? self,
                    backend: ServiceContainer.shared.backendSMSV3,
                    preferences: LucaPreferences.shared)

                self.phoneNumberVerificationService!.verify(phoneNumber: phoneNumber) { success in
                    self.phoneNumberVerificationService = nil
                    if success {
                        observer(.completed)
                    } else {
                        observer(.error(LocalizedTitledErrorValue(
                                            localizedTitle: L10n.Navigation.Basic.error,
                                            errorDescription: L10n.Verification.PhoneNumber.updateFailure)))
                    }
                }

                return Disposables.create()
            }
            .subscribe(on: MainScheduler.instance)

        } else {
            return Completable.empty()
        }
    }

    private func save() -> Completable {
        Completable.from {
            self.currentData.firstName = self.firstNameTextField.textField.text?.sanitize()
            self.currentData.lastName = self.lastNameTextField.textField.text?.sanitize()
            self.currentData.street = self.addressStreetTextField.textField.text?.sanitize()
            self.currentData.houseNumber = self.addressHouseNumberTextField.textField.text?.sanitize()
            self.currentData.postCode = self.addressPostCodeTextField.textField.text?.sanitize()
            self.currentData.city = self.addressCityTextField.textField.text?.sanitize()
            self.currentData.phoneNumber = self.phoneNumberTextField.textField.text?.sanitize()
            self.currentData.email = self.emailTextField.textField.text?.sanitize()
        }
        .andThen(ServiceContainer.shared.userService.update(data: currentData))
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

// MARK: - Accessibility
extension ContactViewController {

    private func setupAccessibility() {
        UIAccessibility.setFocusTo(navigationItem, notification: .layoutChanged)
    }

}
