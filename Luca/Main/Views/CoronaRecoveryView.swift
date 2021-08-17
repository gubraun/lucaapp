import UIKit

class CoronaRecoveryView: DocumentView, DocumentViewProtocol {

    @IBOutlet weak var validUntilLabel: UILabel!
    @IBOutlet weak var validFromLabel: UILabel!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!

    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var expandView: UIView!

    var document: Recovery? {
        didSet {
            setup()
        }
    }

    public static func createView(document: Document, delegate: DocumentViewDelegate?) -> DocumentView? {
        guard let document = document as? Recovery else { return nil }

        let itemView: CoronaRecoveryView = CoronaRecoveryView.fromNib()
        itemView.document = document
        itemView.delegate = delegate

        return itemView
    }

    private func setup() {
        guard let recovery = document else { return }

        wrapperView.layer.cornerRadius = 8
        wrapperView.backgroundColor = .lucaEMGreen

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

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.isEnabled = true
        tapGestureRecognizer.cancelsTouchesInView = true
        addGestureRecognizer(tapGestureRecognizer)

        toggleView(animated: false)
    }

    private func setupQRCodeImage(for recovery: Recovery) {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = QRCodeGenerator.generateQRCode(string: recovery.originalCode)
        if let scaledQr = image?.transformed(by: transform) {
            qrCodeImageView.image = UIImage(ciImage: scaledQr)
        }
    }

    // MARK: - DocumentViewProtocol

    var isExpanded: Bool = false {
        didSet {
            toggleView(animated: true)
        }
    }

    func toggleView(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0.0) { [self] in
            expandView.isHidden = !self.isExpanded
            expandView.alpha = self.isExpanded ? 1.0 : 0.0
        }
    }
}

// MARK: - Actions

extension CoronaRecoveryView {
    @objc
    private func viewTapped(_ sender: UITapGestureRecognizer) {
        isExpanded.toggle()
        toggleView(animated: true)
    }

    @objc
    private func didPressDelete(sender: UIButton) {
        if let recovery = self.document {
            delegate?.didTapDelete(for: recovery)
        }
    }
}
