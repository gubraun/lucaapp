import UIKit
import RxSwift

class CoronaTestTableViewCell: UITableViewCell {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var durationSinceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var doctorLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!

    weak var delegate: DocumentCellDelegate?

    private var disposeBag = DisposeBag()

    var coronaTest: CoronaTest? {
        didSet {
            setup()
        }
    }

    var isExpanded = false

    private func setup() {
        guard let test = coronaTest else { return }

        resultLabel.text = test.isNegative ? L10n.Test.Result.negative : L10n.Test.Result.positive
        backgroundColor = test.isNegative ? UIColor.lucaHealthGreen : UIColor.lucaHealthRed

        categoryLabel.text = test.testType

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
    }

    private func setupQRCodeImage(for test: CoronaTest) {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = QRCodeGenerator.generateQRCode(string: test.originalCode)
        if let scaledQr = image?.transformed(by: transform) {
            qrCodeImageView.image = UIImage(ciImage: scaledQr)
        }
    }

    @objc
    private func didPressDelete(sender: UIButton) {
        if let test = self.coronaTest {
            delegate?.deleteButtonPressed(for: test)
        }
    }
}
