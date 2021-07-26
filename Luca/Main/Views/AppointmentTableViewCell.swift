import UIKit

class AppointmentTableViewCell: UITableViewCell {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!

    weak var delegate: DocumentCellDelegate?

    var appointment: Appointment? {
        didSet {
            setup()
        }
    }

    var isExpanded = false

    private func setup() {
        guard let appointment = appointment else { return }

        typeLabel.text = appointment.type
        dateLabel.text = appointment.date.formattedDateTime
        dateLabel.accessibilityLabel = appointment.date.accessibilityDate
        labLabel.text = appointment.lab.replacingOccurrences(of: "\\s[\\s]+", with: "\n", options: .regularExpression, range: nil)
        addressLabel.text = appointment.address

        qrCodeImageView.layer.cornerRadius = 8
        setupQRCodeImage(for: appointment)

        qrCodeImageView.isAccessibilityElement = true
        qrCodeImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCode

        deleteButton.addTarget(self, action: #selector(didPressDelete(sender:)), for: .touchUpInside)
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor.black.cgColor
        deleteButton.layer.cornerRadius = 16
    }

    private func setupQRCodeImage(for appointment: Appointment) {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = QRCodeGenerator.generateQRCode(string: appointment.qrCode)
        if let scaledQr = image?.transformed(by: transform) {
            qrCodeImageView.image = UIImage(ciImage: scaledQr)
        }
    }

    @objc
    private func didPressDelete(sender: UIButton) {
        if let appointment = self.appointment {
            delegate?.deleteButtonPressed(for: appointment)
        }
    }
}
