import UIKit

class CoronaTestView: DocumentView, DocumentViewProtocol {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var durationSinceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var doctorLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var providerLabel: UILabel!

    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var expandView: UIView!

    weak var timer: Timer?

    var indexPath: IndexPath?

    var document: CoronaTest? {
        didSet {
            setup()
        }
    }

    deinit {
        stopDateUpdateTimer()
    }

    public static func createView(document: Document, delegate: DocumentViewDelegate?) -> DocumentView? {
        guard let document = document as? CoronaTest else { return nil }

        let itemView: CoronaTestView = CoronaTestView.fromNib()
        itemView.document = document
        itemView.delegate = delegate

        return itemView
    }

    private func setup() {
        guard let test = document else { return }

        resultLabel.text = test.isNegative ? L10n.Test.Result.negative : L10n.Test.Result.positive

        wrapperView.layer.cornerRadius = 8
        wrapperView.backgroundColor = test.isNegative ? UIColor.lucaHealthGreen : UIColor.white

        categoryLabel.text = test.testType.localized

        durationSinceLabel.text = test.date.durationSinceDate
        dateLabel.text = test.date.formattedDateTime
        dateLabel.accessibilityLabel = test.date.accessibilityDate
        labLabel.text = test.laboratory.replacingOccurrences(of: "\\s[\\s]+", with: "\n", options: .regularExpression, range: nil)
        doctorLabel.text = test.doctor

        qrCodeImageView.layer.cornerRadius = 8
        setupQRCodeImage(for: test)

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
        providerLabel.text = test.provider

        toggleView(animated: false)
        startDateUpdateTimer()
    }

    private func setupQRCodeImage(for test: CoronaTest) {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = QRCodeGenerator.generateQRCode(string: test.originalCode)
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

            layoutIfNeeded()
        }
    }

    func startDateUpdateTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.durationSinceLabel.text = self?.document?.date.durationSinceDate
        }
    }

    func stopDateUpdateTimer() {
        timer?.invalidate()
    }
}

// MARK: - Actions

extension CoronaTestView {
    @objc
    private func viewTapped(_ sender: UITapGestureRecognizer) {
        isExpanded.toggle()
        toggleView(animated: true)
    }

    @objc
    private func didPressDelete(sender: UIButton) {
        if let test = self.document {
            delegate?.didTapDelete(for: test)
        }
    }
}
