import UIKit
import RxSwift

class CoronaVaccineTableViewCell: UITableViewCell {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var vaccinesStackView: UIStackView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!

    weak var delegate: DocumentCellDelegate?

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

        dateLabel.text = vaccine.date.formattedDate
        dateLabel.accessibilityLabel = vaccine.date.accessibilityDate
        labLabel.text = vaccine.laboratory

        setupVaccinesStackView(for: vaccine)

        qrCodeImageView.layer.cornerRadius = 8
        setupQRCodeImage(for: vaccine)

        qrCodeImageView.isAccessibilityElement = true
        qrCodeImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCode

        deleteButton.addTarget(self, action: #selector(didPressDelete(sender:)), for: .touchUpInside)
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor.lucaBlack.cgColor
        deleteButton.layer.cornerRadius = 16
    }

    private func createProcedureView(for procedure: BaerCoronaProcedure, order: Int) -> UIView {
        let procedureView = UIView()

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = .montserratTableViewDescription
        descriptionLabel.textColor = .black
        descriptionLabel.text = L10n.Vaccine.Result.description(order)
        procedureView.addSubview(descriptionLabel)

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .montserratDataAccessAlertDescriptionBold
        dateLabel.textColor = .black

        let date = Date(timeIntervalSince1970: TimeInterval(procedure.date))
        dateLabel.text = "\(date.formattedDateTime)"
        procedureView.addSubview(dateLabel)

        let vaccineLabel = UILabel()
        vaccineLabel.translatesAutoresizingMaskIntoConstraints = false
        vaccineLabel.font = .montserratDataAccessAlertDescriptionBold
        vaccineLabel.textColor = .black
        vaccineLabel.text = procedure.type.category
        procedureView.addSubview(vaccineLabel)

        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: procedureView.topAnchor, constant: 0),
            descriptionLabel.leadingAnchor.constraint(equalTo: procedureView.leadingAnchor, constant: 0),
            descriptionLabel.widthAnchor.constraint(equalToConstant: 90),
            descriptionLabel.heightAnchor.constraint(equalToConstant: 18),

            dateLabel.topAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: 0),
            dateLabel.trailingAnchor.constraint(equalTo: procedureView.trailingAnchor, constant: 0),
            dateLabel.leadingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor, constant: 18),
            dateLabel.heightAnchor.constraint(equalToConstant: 18),

            vaccineLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            vaccineLabel.leadingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: 0),
            vaccineLabel.trailingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 0),
            vaccineLabel.heightAnchor.constraint(equalToConstant: 18),
            vaccineLabel.bottomAnchor.constraint(equalTo: procedureView.bottomAnchor, constant: 0)
                    ])

        return procedureView
    }

    private func setupVaccinesStackView(for vaccine: BaerCoronaTest) {
        vaccinesStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        for (index, procedure) in vaccine.procedures.enumerated() {
            let order = vaccine.procedures.count - index
            let procedureView = createProcedureView(for: procedure, order: order)
            vaccinesStackView.addArrangedSubview(procedureView)
        }
    }

    private func setupQRCodeImage(for vaccine: CoronaTest) {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = QRCodeGenerator.generateQRCode(string: vaccine.originalCode)
        if let scaledQr = image?.transformed(by: transform) {
            qrCodeImageView.image = UIImage(ciImage: scaledQr)
        }
    }

    @objc
    private func didPressDelete(sender: UIButton) {
        if let vaccine = self.coronaVaccine {
            delegate?.deleteButtonPressed(for: vaccine)
        }
    }
}
