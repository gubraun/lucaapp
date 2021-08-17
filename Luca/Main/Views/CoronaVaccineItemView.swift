import UIKit

class CoronaVaccineItemView: DocumentView, DocumentViewProtocol, HorizontalGroupable {
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var vaccinesStackView: UIStackView!
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!

    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var expandView: UIView!

    weak var horizoantalDocumentViewDelegate: HorizontalDocumentListViewDelegate?
    let groupedKey = "CoronaVaccineItemView"

    var document: Vaccination? {
        didSet {
            setup()
        }
    }

    public static func createView(document: Document, delegate: DocumentViewDelegate?) -> DocumentView? {
        guard let document = document as? Vaccination else { return nil }

        let itemView: CoronaVaccineItemView = CoronaVaccineItemView.fromNib()
        itemView.document = document
        itemView.delegate = delegate

        return itemView
    }

    private func setup() {
        guard let vaccination = document else { return }

        let doseNumber = vaccination.doseNumber
        let dosesTotal = vaccination.dosesTotalNumber
        wrapperView.layer.cornerRadius = 8
        if vaccination.isComplete() {
            wrapperView.backgroundColor = UIColor.lucaEMGreen
            resultLabel.text = L10n.Vaccine.Result.complete(doseNumber, dosesTotal)
        } else {
            wrapperView.backgroundColor = UIColor.lucaBeige
            resultLabel.text = L10n.Vaccine.Result.partially(doseNumber, dosesTotal)
        }

        backgroundColor = .clear
        dateLabel.text = vaccination.date.formattedDate
        dateLabel.accessibilityLabel = vaccination.date.accessibilityDate
        labLabel.text = vaccination.laboratory
        dateOfBirthLabel.text = vaccination.dateOfBirth.formattedDate

        setupVaccinesStackView(for: vaccination)

        qrCodeImageView.layer.cornerRadius = 8
        setupQRCodeImage(for: vaccination)

        qrCodeImageView.isAccessibilityElement = true
        qrCodeImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCode

        deleteButton.addTarget(self, action: #selector(didPressDelete(sender:)), for: .touchUpInside)
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor.lucaBlack.cgColor
        deleteButton.layer.cornerRadius = 16

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.isEnabled = true
        tapGestureRecognizer.cancelsTouchesInView = true
        addGestureRecognizer(tapGestureRecognizer)

        toggleView(animated: false)
    }

    private func createProcedureView(for vaccination: Vaccination) -> UIView {
        let procedureView = UIView()

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = .montserratTableViewDescription
        descriptionLabel.textColor = .black
        descriptionLabel.text = L10n.Vaccine.Result.description(vaccination.doseNumber)
        procedureView.addSubview(descriptionLabel)

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .montserratDataAccessAlertDescriptionBold
        dateLabel.textColor = .black

        dateLabel.text = vaccination.date.formattedDate
        procedureView.addSubview(dateLabel)

        let vaccineLabel = UILabel()
        vaccineLabel.translatesAutoresizingMaskIntoConstraints = false
        vaccineLabel.font = .montserratDataAccessAlertDescriptionBold
        vaccineLabel.textColor = .black
        vaccineLabel.text = vaccination.vaccineType
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

    private func setupVaccinesStackView(for vaccine: Vaccination) {
        vaccinesStackView.removeAllArrangedSubviews()

        let procedureView = createProcedureView(for: vaccine)
        vaccinesStackView.addArrangedSubview(procedureView)
    }

    private func setupQRCodeImage(for vaccine: Document) {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = QRCodeGenerator.generateQRCode(string: vaccine.originalCode)
        if let scaledQr = image?.transformed(by: transform) {
            qrCodeImageView.image = UIImage(ciImage: scaledQr)
        }
    }

    // MARK: - DocumentViewProtocol

    public var isExpanded = false

    public func toggleView(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0.0, delay: 0.0, options: .beginFromCurrentState) { [self] in
            expandView.isHidden = !isExpanded
            expandView.alpha = isExpanded ? 1.0 : 0.0

            if animated {
                delegate?.didToggleView()
            }
        }
    }
}

// MARK: - Actions

extension CoronaVaccineItemView {
    @objc
    private func viewTapped(_ sender: UITapGestureRecognizer) {
        isExpanded.toggle()
        toggleView(animated: true)
    }
    @objc

    private func didPressDelete(sender: UIButton) {
        if let vaccination = document {
            delegate?.didTapDelete(for: vaccination)
        }
    }
}
