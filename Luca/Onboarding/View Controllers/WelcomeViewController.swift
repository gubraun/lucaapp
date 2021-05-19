import UIKit
import SimpleCheckbox
import TTTAttributedLabel

class WelcomeViewController: UIViewController {

    @IBOutlet weak var termsAndConditionsCheckbox: Checkbox!
    @IBOutlet weak var termsAndConditionsCheckboxError: UIImageView!
    @IBOutlet weak var termsAndConditionsTextView: TTTAttributedLabel!
    @IBOutlet weak var privacyPolicyCheckbox: Checkbox!
    @IBOutlet weak var privacyPolicyCheckboxError: UIImageView!
    @IBOutlet weak var privacyPolicyTextView: TTTAttributedLabel!

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!

    @IBOutlet weak var logoImageView: UIImageView!

    var initialStatusBarStyle: UIStatusBarStyle?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Sometimes it won't be picked up, although in IB set correctly
        logoImageView.image = logoImageView.image?.withRenderingMode(.alwaysTemplate)
        logoImageView.tintColor = UIColor.white

        setupCheckbox(privacyPolicyCheckbox, accessibilityLabel: L10n.WelcomeViewController.PrivacyPolicy.checkboxAccessibility)
        setupCheckbox(termsAndConditionsCheckbox, accessibilityLabel: L10n.WelcomeViewController.TermsAndConditions.checkboxAccessibility)

        privacyPolicyCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        termsAndConditionsCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)

        setupCheckboxError(termsAndConditionsCheckboxError)
        setupCheckboxError(privacyPolicyCheckboxError)

        descriptionLabel.text = L10n.Welcome.Info.description

        okButton.layer.cornerRadius = okButton.frame.size.height / 2

        buildTappableLabel(
            wholeTerm: L10n.WelcomeViewController.PrivacyPolicy.checkboxMessage,
            linkTerms: [L10n.WelcomeViewController.termPrivacyPolicy],
            linkURLs: [URL(string: L10n.WelcomeViewController.linkPrivacyPolicy)!],
            tappableLabel: privacyPolicyTextView)

        buildTappableLabel(
            wholeTerm: L10n.WelcomeViewController.TermsAndConditions.checkboxMessage,
            linkTerms: [L10n.WelcomeViewController.termTC],
            linkURLs: [URL(string: L10n.WelcomeViewController.linkTC)!],
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
            return
        }
        LucaPreferences.shared.welcomePresented = true
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func checkboxValueChanged(_ sender: Checkbox) {
        sender.removeErrorStyling()
        sender.accessibilityValue = sender.isChecked ? L10n.WelcomeViewController.TermsAndConditions.checkboxAccessibilityOn : L10n.WelcomeViewController.TermsAndConditions.checkboxAccessibilityOff
        if sender == termsAndConditionsCheckbox {
            termsAndConditionsCheckboxError.isHidden = true
        } else if sender == privacyPolicyCheckbox {
            privacyPolicyCheckboxError.isHidden = true
        }
    }

    private func validateCheckboxes() -> Bool {
        termsAndConditionsCheckbox.isChecked && privacyPolicyCheckbox.isChecked
    }

    private func highlightUncheckedCheckboxes() {
        if !termsAndConditionsCheckbox.isChecked {
            termsAndConditionsCheckbox.styleForError()
            termsAndConditionsCheckboxError.isHidden = false
        }

        if !privacyPolicyCheckbox.isChecked {
            privacyPolicyCheckbox.styleForError()
            privacyPolicyCheckboxError.isHidden = false
        }
    }

    private func buildTappableLabel(wholeTerm: String, linkTerms: [String], linkURLs: [URL], tappableLabel: TTTAttributedLabel) {
        if linkTerms.count != linkURLs.count {
            self.log("Terms and links should be the same size", entryType: .error)
            return
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: tappableLabel.font.bold()
        ]
        let clickedAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: UIColor.lucaGrey,
            .font: tappableLabel.font.bold()
        ]

        let nsstring = NSString(string: wholeTerm)
        tappableLabel.text = nsstring
        tappableLabel.linkAttributes = attributes
        tappableLabel.activeLinkAttributes = clickedAttributes
        tappableLabel.delegate = self
        for (index, linkTerm) in linkTerms.enumerated() {
            let range = nsstring.range(of: linkTerm)
            tappableLabel.addLink(to: linkURLs[index], with: range)
        }
    }
}

extension WelcomeViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
