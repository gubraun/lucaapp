import UIKit
import PhoneNumberKit

class PhoneNumberConfirmationViewController: UIViewController {

    public var onCancel: (() -> Void)?
    public var onSuccess: (() -> Void)?

    var phoneNumber: PhoneNumber!
    var phoneNumberKit = PhoneNumberKit()

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIAccessibility.setFocusTo(titleLabel)
    }

    func setupViews() {
        let formattedNumber = phoneNumberKit.format(phoneNumber, toType: .e164)
        descriptionLabel.text = phoneNumber.type == PhoneNumberType.mobile ? L10n.PhoneNumber.Confirmation.Description.mobile : L10n.PhoneNumber.Confirmation.Description.fixed
        phoneNumberLabel.text = formattedNumber
    }

    @IBAction func cancelPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        self.onCancel?()
    }

    @IBAction func confirmPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        self.onSuccess?()
    }

}
