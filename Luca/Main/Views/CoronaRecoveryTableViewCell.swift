import UIKit

class CoronaRecoveryTableViewCell: UITableViewCell {

    @IBOutlet weak var validUntilLabel: UILabel!
    @IBOutlet weak var validFromLabel: UILabel!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!

    weak var delegate: DocumentCellDelegate?

    var recovery: Recovery? {
        didSet {
            setup()
        }
    }

    var isExpanded = false

    private func setup() {
        guard let recovery = recovery else { return }

        validUntilLabel.text = recovery.validUntilDate.formattedDate
        validUntilLabel.accessibilityLabel = recovery.validUntilDate.accessibilityDate
        validFromLabel.text = recovery.validFromDate.formattedDateTime
        validFromLabel.accessibilityLabel = recovery.validFromDate.accessibilityDate
        labLabel.text = recovery.laboratory.replacingOccurrences(of: "\\s[\\s]+", with: "\n", options: .regularExpression, range: nil)
        dateOfBirthLabel.text = recovery.dateOfBirth.formattedDate
        dateOfBirthLabel.accessibilityLabel = recovery.dateOfBirth.accessibilityDate

        qrCodeImageView.layer.cornerRadius = 8
        setupQRCodeImage(for: recovery)

        qrCodeImageView.isAccessibilityElement = true
        qrCodeImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCode

        deleteButton.addTarget(self, action: #selector(didPressDelete(sender:)), for: .touchUpInside)
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor.black.cgColor
        deleteButton.layer.cornerRadius = 16
    }

    private func setupQRCodeImage(for recovery: Recovery) {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = QRCodeGenerator.generateQRCode(string: recovery.originalCode)
        if let scaledQr = image?.transformed(by: transform) {
            qrCodeImageView.image = UIImage(ciImage: scaledQr)
        }
    }

    @objc
    private func didPressDelete(sender: UIButton) {
        if let recovery = self.recovery {
            delegate?.deleteButtonPressed(for: recovery)
        }
    }
}
