import UIKit
import Nantes

class AlertWithLinkViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: NantesLabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!

    private var confirmAction: (() -> Void)?
    private var cancelAction: (() -> Void)?
    private var titleText: String?
    private var descriptionText: String?
    private var linkText: String?
    private var url: URL?
    private var hasCancelButton = true
    private var continueButtonTitle: String?
    private var accessibilityText: String?
    private var accessibilityTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        configureSubviews()
    }

    func setup(withTitle title: String,
               description: String,
               accessibilityTitle: String? = nil,
               accessibility: String? = nil,
               link: String,
               url: URL?,
               hasCancelButton: Bool = true,
               continueButtonTitle: String? = nil,
               confirmAction: (() -> Void)?,
               cancelAction: (() -> Void)? = nil) {
        self.titleText = title
        self.descriptionText = description
        self.linkText = link
        self.url = url
        self.confirmAction = confirmAction
        self.hasCancelButton = hasCancelButton
        self.cancelAction = cancelAction
        self.continueButtonTitle = continueButtonTitle
        self.accessibilityText = accessibility
        self.accessibilityTitle = accessibilityTitle
    }

    private func configureSubviews() {
        guard let title = titleText, let description = descriptionText, let link = linkText else { return }

        descriptionLabel.delegate = self
        titleLabel.text = title

        cancelButton.isHidden = !hasCancelButton
        if let continueButtonTitle = continueButtonTitle {
            continueButton.setTitle(continueButtonTitle, for: .normal)
        }

        setupDescriptionLabel(with: description, linkText: link, url: url)
        setupAccessibility()
    }

    private func setupDescriptionLabel(with description: String, linkText: String, url: URL?) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.montserratDataAccessAlertDescription,
            .foregroundColor: UIColor.black
        ]
        let attrText = NSMutableAttributedString(string: description, attributes: attributes)
        descriptionLabel.attributedText = attrText
        descriptionLabel.numberOfLines = 0

        if let linkRange = description.range(of: linkText),
           let url = url {
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.black,
                .font: UIFont.montserratDataAccessAlertDescription.bold()
            ]
            let clickedAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lucaGrey,
                .font: UIFont.montserratDataAccessAlertDescription.bold()
            ]

            descriptionLabel.linkAttributes = linkAttributes
            descriptionLabel.activeLinkAttributes = clickedAttributes
            descriptionLabel.addLink(to: url, withRange: NSRange(linkRange, in: description))
        }

        descriptionLabel.accessibilityTraits = .link
    }

    @IBAction func confirmActionTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        confirmAction?()
    }

    @IBAction func cancelActionTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        if let cancel = cancelAction {
            cancel()
        }
    }
}

extension AlertWithLinkViewController: NantesLabelDelegate {

    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }

}

// MARK: - Accessibility
extension AlertWithLinkViewController {

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header
        if let accessibility = accessibilityText {
            descriptionLabel.accessibilityLabel = accessibility
        }

        if let title = accessibilityTitle {
            titleLabel.accessibilityLabel = title
        }
    }

}
