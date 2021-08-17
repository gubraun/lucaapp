import UIKit

class DoneViewController: UIViewController {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionLabel.text = L10n.Done.description
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleLabel.accessibilityTraits = .header
    }

    @IBAction func okayPressed(_ sender: UIButton) {
        LucaPreferences.shared.donePresented = true

        // don't show new terms to new users
        if let currentBuildVersion = Bundle.main.buildVersionNumber,
           let version = Int(currentBuildVersion) {
            LucaPreferences.shared.termsAcceptedVersion = version
        }

        self.dismiss(animated: true, completion: nil)
    }

}
