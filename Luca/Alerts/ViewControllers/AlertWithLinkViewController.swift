import UIKit
import TTTAttributedLabel

class AlertWithLinkViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: TTTAttributedLabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!

    private var confirmAction: (() -> Void)?
    private var titleText: String?
    private var descriptionText: String?
    private var linkText: String?
    private var url: URL?
    private var hasCancelButton = true
    private var continueButtonTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        configureSubviews()

        view.accessibilityElements = [titleLabel, descriptionLabel, cancelButton, continueButton].map { $0 as Any }
    }

    func setup(withTitle title: String, description: String, link: String, url: URL?, hasCancelButton: Bool = true, continueButtonTitle: String? = nil, confirmAction: (() -> Void)?) {
        self.titleText = title
        self.descriptionText = description
        self.linkText = link
        self.url = url
        self.confirmAction = confirmAction
        self.hasCancelButton = hasCancelButton
        self.continueButtonTitle = continueButtonTitle
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
    }

    private func setupDescriptionLabel(with description: String, linkText: String, url: URL?) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.montserratDataAccessAlertDescription,
            .foregroundColor: UIColor.black
        ]
        let attrText = NSMutableAttributedString(string: description, attributes: attributes)
        descriptionLabel.text = attrText

        if let linkRange = description.range(of: linkText) {
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lucaPurple,
                .font: UIFont.montserratDataAccessAlertDescription.bold()
            ]
            let clickedAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lucaGrey,
                .font: UIFont.montserratDataAccessAlertDescription.bold()
            ]

            descriptionLabel.linkAttributes = linkAttributes
            descriptionLabel.activeLinkAttributes = clickedAttributes
            descriptionLabel.addLink(to: url, with: NSRange(linkRange, in: description))
        }

        descriptionLabel.accessibilityTraits = .link
    }

    @IBAction func confirmActionTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        confirmAction?()
    }

    @IBAction func cancelActionTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension AlertWithLinkViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
