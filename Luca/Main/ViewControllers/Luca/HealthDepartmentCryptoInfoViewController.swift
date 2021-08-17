import Foundation
import UIKit
import RxSwift

class HealthDepartmentCryptoInfoViewController: UIViewController {

    @IBOutlet weak var downloadCertificateChain: UIButton!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!

    /// Primitive name caching
    private static var issuerName: String?
    private static var date: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Default values
        nameLabel.text = ""
        dateLabel.text = ""

        // Cached values
        if let issuerName = HealthDepartmentCryptoInfoViewController.issuerName,
           let date = HealthDepartmentCryptoInfoViewController.date {
            nameLabel.text = issuerName
            dateLabel.text = date
            return
        }

        // Generating new values
        if let newestKeyId: DailyKeyIndex = ServiceContainer.shared.dailyKeyRepository.newestId {

            // Date string
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let dateString = dateFormatter.string(from: newestKeyId.createdAt)
            HealthDepartmentCryptoInfoViewController.date = dateString
            dateLabel.text = dateString

            // Issuer name
            let backend = ServiceContainer.shared.backendDailyKeyV3!

            _ = backend.retrievePubKey(keyId: newestKeyId.keyId)
                .asSingle()
                .flatMap { backend.retrieveIssuerKeys(issuerId: $0.issuerId).asSingle() }
                .observe(on: MainScheduler.instance)
                .do(onSuccess: { key in
                    HealthDepartmentCryptoInfoViewController.issuerName = key.name
                    self.nameLabel.text = key.name
                })
                .subscribe()
        }

        setupAccessibility()
    }

    private func setupViews() {
        // Setup navigationbar title
        title = L10n.General.healthDepartmentKey
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont.montserratViewControllerTitle,
                                                                        NSAttributedString.Key.foregroundColor: UIColor.white]

        // Setup sublabel
        subtitleLabel.text = L10n.General.healthDepartmentKey
    }
}

// MARK: - Accessibility
extension HealthDepartmentCryptoInfoViewController {

    private func setupAccessibility() {
        UIAccessibility.setFocusTo(subtitleLabel, notification: .screenChanged, delay: 0.8)
    }

}
