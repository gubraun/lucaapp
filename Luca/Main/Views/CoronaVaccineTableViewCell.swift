import UIKit
import RxSwift

class CoronaVaccineTableViewCell: UITableViewCell {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var vaccinesStackView: UIStackView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!

    private var disposeBag = DisposeBag()

    var coronaVaccine: BaerCoronaTest? {
        didSet {
            setup()
        }
    }

    var isExpanded = false

    private func setup() {
        guard let vaccine = coronaVaccine else { return }

        switch vaccine.vaccineState() {
        case .complete:
            backgroundColor = UIColor.lucaHealthYellow
            resultLabel.text = L10n.Vaccine.Result.complete
        case .secondPending:
            backgroundColor = UIColor.lucaLightGrey
            resultLabel.text = L10n.Vaccine.Result.complete
        default:
            backgroundColor = UIColor.lucaLightGrey
            resultLabel.text = L10n.Vaccine.Result.partially
        }

        categoryLabel.text = L10n.Vaccine.Result.default

        dateLabel.text = vaccine.date.formattedDate
        dateLabel.accessibilityLabel = vaccine.date.accessibilityDate
        labLabel.text = vaccine.laboratory

        setupVaccinesStackView(for: vaccine)

        qrCodeImageView.layer.cornerRadius = 8
        setupQRCodeImage(for: vaccine)

        qrCodeImageView.isAccessibilityElement = true
        qrCodeImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCode
    }

    private func setupVaccinesStackView(for vaccine: BaerCoronaTest) {
        vaccinesStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        for (index, procedure) in vaccine.procedures.enumerated() {

            let descriptionLabel = UILabel()
            descriptionLabel.font = .montserratTableViewDescription
            descriptionLabel.textColor = .black
            descriptionLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true

            let order = vaccine.procedures.count - index
            descriptionLabel.text = L10n.Vaccine.Result.description(order, procedure.type.category)

            let dateLabel = UILabel()
            dateLabel.font = .montserratDataAccessAlertDescriptionBold
            dateLabel.textColor = .black
            dateLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true

            let date = Date(timeIntervalSince1970: TimeInterval(procedure.date))
            dateLabel.text = "\(date.formattedDate)"

            vaccinesStackView.addArrangedSubview(descriptionLabel)
            vaccinesStackView.addArrangedSubview(dateLabel)
        }
    }

    private func setupQRCodeImage(for vaccine: CoronaTest) {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = QRCodeGenerator.generateQRCode(string: vaccine.originalCode)
        if let scaledQr = image?.transformed(by: transform) {
            qrCodeImageView.image = UIImage(ciImage: scaledQr)
        }
    }

}
