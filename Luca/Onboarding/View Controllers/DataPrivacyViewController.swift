import UIKit

class DataPrivacyViewController: UIViewController {

    @IBOutlet weak var descriptionTitle: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var gotItButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func setupViews() {
        setupAccessibility()
        descriptionLabel.text = L10n.DataPrivacy.Info.description
        descriptionTitle.text = L10n.DataPrivacy.Info.title
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gotItButton.layer.cornerRadius = gotItButton.frame.size.height / 2
    }

    @IBAction func gotItButtonPressed(_ sender: UIButton) {
        LucaPreferences.shared.dataPrivacyPresented = true
        self.dismiss(animated: true, completion: nil)
    }

}

// MARK: - Accessibility
extension DataPrivacyViewController {

    private func setupAccessibility() {
        descriptionTitle.accessibilityTraits = .header
        UIAccessibility.setFocusTo(descriptionTitle, notification: .layoutChanged, delay: 0.8)
    }

}
