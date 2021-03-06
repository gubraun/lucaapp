import UIKit
import SimpleCheckbox
import Nantes

class WelcomeViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var termsAndConditionsCheckbox: Checkbox!
    @IBOutlet weak var termsAndConditionsCheckboxError: UIImageView!
    @IBOutlet weak var termsAndConditionsTextView: NantesLabel!
    @IBOutlet weak var privacyPolicyTextView: NantesLabel!

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!

    @IBOutlet weak var logoImageView: UIImageView!

    var initialStatusBarStyle: UIStatusBarStyle?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Sometimes it won't be picked up, although in IB set correctly
        logoImageView.image = logoImageView.image?.withRenderingMode(.alwaysTemplate)
        logoImageView.tintColor = UIColor.white

        setupCheckbox(termsAndConditionsCheckbox, accessibilityLabel: L10n.WelcomeViewController.TermsAndConditions.checkboxAccessibility)

        setupCheckboxError(termsAndConditionsCheckboxError)

        descriptionLabel.text = L10n.Welcome.Info.description

        okButton.layer.cornerRadius = okButton.frame.size.height / 2

        buildTappableLabel(
            linkDescription: L10n.WelcomeViewController.PrivacyPolicy.message,
            linkTerm: L10n.WelcomeViewController.termPrivacyPolicy,
            linkURL: L10n.WelcomeViewController.linkPrivacyPolicy,
            tappableLabel: privacyPolicyTextView)

        buildTappableLabel(
            linkDescription: L10n.WelcomeViewController.TermsAndConditions.checkboxMessage,
            linkTerm: L10n.WelcomeViewController.termTC,
            linkURL: L10n.WelcomeViewController.linkTC,
            tappableLabel: termsAndConditionsTextView)
    }

    private func setupCheckbox(_ checkbox: Checkbox, accessibilityLabel: String) {
        checkbox.checkedBorderColor = .white
        checkbox.uncheckedBorderColor = .white
        checkbox.borderStyle = .square
        checkbox.borderLineWidth = 1
        checkbox.borderCornerRadius = 2

        checkbox.checkmarkStyle = .circle
        checkbox.checkmarkColor = UIColor.white

        checkbox.accessibilityLabel = accessibilityLabel
        checkbox.isAccessibilityElement = true
    }

    private func setupCheckboxError(_ errorImage: UIImageView) {
        let image = UIImage(cgImage: #imageLiteral(resourceName: "infoIcon").cgImage!, scale: #imageLiteral(resourceName: "infoIcon").scale, orientation: .down)
        errorImage.image = image.withRenderingMode(.alwaysTemplate)
        errorImage.tintColor = .lucaError
        errorImage.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initialStatusBarStyle = UIApplication.shared.statusBarStyle
        if #available(iOS 13.0, *) {
            UIApplication.shared.setStatusBarStyle(.darkContent, animated: animated)
        } else {
            UIApplication.shared.setStatusBarStyle(.default, animated: animated)
        }
        setupAccessibility()
    }

    @IBAction func termsAndConditionsPressed(_ sender: Checkbox) {
        sender.removeErrorStyling()
        termsAndConditionsCheckboxError.isHidden = true
        termsAndConditionsCheckbox.accessibilityValue = sender.isChecked ? L10n.WelcomeViewController.TermsAndConditions.Checkbox.confirmed : L10n.WelcomeViewController.TermsAndConditions.Checkbox.notConfirmed
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let statusBarStyle = initialStatusBarStyle {
            UIApplication.shared.setStatusBarStyle(statusBarStyle, animated: animated)
        }
    }

    @IBAction func onOkButton(_ sender: UIButton) {
        guard validateCheckboxes() else {
            highlightUncheckedCheckboxes()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .announcement, argument: L10n.Welcome.Checkboxes.accessibilityError)
            }
            return
        }
        LucaPreferences.shared.welcomePresented = true
        self.dismiss(animated: true, completion: nil)
    }

    private func validateCheckboxes() -> Bool {
        termsAndConditionsCheckbox.isChecked
    }

    private func highlightUncheckedCheckboxes() {
        if !termsAndConditionsCheckbox.isChecked {
            termsAndConditionsCheckbox.styleForError()
            termsAndConditionsCheckboxError.isHidden = false
        }
    }

    private func buildTappableLabel(linkDescription: String, linkTerm: String, linkURL: String, tappableLabel: NantesLabel) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: tappableLabel.font as Any,
            .foregroundColor: UIColor.white
        ]
        let attrText = NSMutableAttributedString(string: linkDescription, attributes: attributes)
        tappableLabel.attributedText = attrText

        tappableLabel.numberOfLines = 0
        tappableLabel.delegate = self

        let linkAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: tappableLabel.font.bold() as Any
        ]
        let clickedAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: UIColor.lucaGrey,
            .font: tappableLabel.font.bold() as Any
        ]
        tappableLabel.linkAttributes = linkAttributes
        tappableLabel.activeLinkAttributes = clickedAttributes
        if let linkRange = linkDescription.range(of: linkTerm),
           let url = URL(string: linkURL) {
            tappableLabel.addLink(to: url, withRange: NSRange(linkRange, in: linkDescription))
        }
    }
}

extension WelcomeViewController: NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }
}

extension WelcomeViewController: UnsafeAddress, LogUtil {}

private extension Checkbox {
    func styleForError() {
        uncheckedBorderColor = .lucaError
        setNeedsDisplay()
    }

    func removeErrorStyling() {
        uncheckedBorderColor = .white
    }
}

// MARK: - Accessibility
extension WelcomeViewController {

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header

        self.view.accessibilityElements = [titleLabel, descriptionLabel, privacyPolicyTextView, termsAndConditionsCheckbox, termsAndConditionsTextView, okButton].map { $0 as Any }

        termsAndConditionsCheckbox.accessibilityValue = termsAndConditionsCheckbox.isChecked ?
            L10n.WelcomeViewController.TermsAndConditions.Checkbox.confirmed : L10n.WelcomeViewController.TermsAndConditions.Checkbox.notConfirmed

        UIAccessibility.setFocusTo(titleLabel, notification: .layoutChanged, delay: 0.8)
    }

}
