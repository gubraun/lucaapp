import UIKit

class LucaAlertViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var firstButton: UIButton!

    /// Title of the alert
    var alertTitle: String {
        get {
            return titleLabel.text ?? ""
        }
        set {
            titleLabel.text = newValue
        }
    }

    var message: String {
        get {
            return messageLabel.text ?? ""
        }
        set {
            messageLabel.text = newValue
        }
    }

    var onFirstButtonAction: (() -> Void)?
    var __onDidDisappear: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAccessibility()
    }

    @IBAction func onFirstButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        onFirstButtonAction?()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        __onDidDisappear?()
    }
}

// MARK: - Accessibility
extension LucaAlertViewController {

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header
        UIAccessibility.setFocusTo(titleLabel, notification: .screenChanged, delay: 0.8)
    }

}
