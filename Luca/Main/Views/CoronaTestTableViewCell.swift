import UIKit
import RxSwift

class CoronaTestTableViewCell: UITableViewCell {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var doctorLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!

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

        dateLabel.text = test.date.formattedDate
        dateLabel.accessibilityLabel = test.date.accessibilityDate
        labLabel.text = test.laboratory
        doctorLabel.text = test.doctor

        qrCodeImageView.layer.cornerRadius = 8
        setupQRCodeImage(for: test)

        qrCodeImageView.isAccessibilityElement = true
        qrCodeImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCode
    }

    private func setupQRCodeImage(for test: CoronaTest) {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = QRCodeGenerator.generateQRCode(string: test.originalCode)
        if let scaledQr = image?.transformed(by: transform) {
            qrCodeImageView.image = UIImage(ciImage: scaledQr)
        }
    }

}
