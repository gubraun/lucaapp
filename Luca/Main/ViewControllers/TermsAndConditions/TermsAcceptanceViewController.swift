import UIKit
import Nantes

class TermsAcceptanceViewController: UIViewController {

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = L10n.General.title
        titleLabel.font = UIFont.oggViewControllerTitle
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        return titleLabel
    }()

    private lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.text = L10n.General.Greeting.title
        subTitleLabel.font = UIFont.montserratViewControllerTitle
        subTitleLabel.textColor = .white
        view.addSubview(subTitleLabel)

        return subTitleLabel
    }()

    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.text = L10n.Terms.Acceptance.description
        descriptionLabel.font = UIFont.montserratTableViewDescription
        descriptionLabel.textColor = .white
        descriptionLabel.numberOfLines = 0
        view.addSubview(descriptionLabel)

        return descriptionLabel
    }()

    private lazy var linksLabel: NantesLabel = {
        let linkDescription = L10n.Terms.Acceptance.linkDescription

        let linksLabel = NantesLabel(frame: .zero)
        linksLabel.numberOfLines = 0
        linksLabel.delegate = self

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.montserratTableViewDescription,
            .foregroundColor: UIColor.white
        ]
        let attrText = NSMutableAttributedString(string: linkDescription, attributes: attributes)
        linksLabel.attributedText = attrText

        let linkAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: UIFont.montserratTableViewDescription.bold()
        ]
        let clickedAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: UIFont.montserratTableViewDescription.bold(),
            .foregroundColor: UIColor.lucaGrey
        ]

        linksLabel.linkAttributes = linkAttributes
        linksLabel.activeLinkAttributes = clickedAttributes

        let termTCLink = L10n.WelcomeViewController.termTC
        if let linkRange = linkDescription.range(of: termTCLink),
           let url = URL(string: L10n.WelcomeViewController.linkTC) {
            linksLabel.addLink(to: url, withRange: NSRange(linkRange, in: linkDescription))
        }

        let termPrivacyPolicyLink = L10n.WelcomeViewController.termPrivacyPolicy
        if let linkRange = linkDescription.range(of: termPrivacyPolicyLink),
           let url = URL(string: L10n.WelcomeViewController.linkPrivacyPolicy) {
            linksLabel.addLink(to: url, withRange: NSRange(linkRange, in: linkDescription))
        }
        view.addSubview(linksLabel)

        return linksLabel
    }()

    private lazy var acceptButton: UIButton = {
        let acceptButton = UIButton(type: .custom)
        acceptButton.setTitle(L10n.Navigation.Basic.agree, for: .normal)
        acceptButton.setTitleColor(.black, for: .normal)
        acceptButton.titleLabel?.font = UIFont.montserratDataAccessAlertDescriptionBold
        acceptButton.backgroundColor = .lucaGradientWelcomeBegin
        acceptButton.layer.cornerRadius = 24
        acceptButton.addTarget(self, action: #selector(self.acceptPressed), for: .touchUpInside)
        view.addSubview(acceptButton)

        return acceptButton
    }()

    private lazy var moreButton: UIButton = {
        let moreButton = UIButton(type: .system)
        moreButton.setImage(UIImage(named: "viewMore"), for: .normal)
        moreButton.backgroundColor = .clear
        moreButton.tintColor = .white
        moreButton.addTarget(self, action: #selector(self.morePressed), for: .touchUpInside)
        view.addSubview(moreButton)

        return moreButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setupAccessibility()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: Setup
    private func setupContraints() {
        titleLabel.setAnchor(top: view.safeAreaLayoutGuide.topAnchor,
                             leading: view.leadingAnchor,
                             bottom: nil,
                             trailing: nil,
                             padding: UIEdgeInsets(top: 32, left: 32, bottom: 0, right: 32),
                             size: CGSize(width: 0, height: 48))

        subTitleLabel.setAnchor(top: titleLabel.bottomAnchor,
                                leading: view.leadingAnchor,
                                bottom: nil,
                                trailing: view.trailingAnchor,
                                padding: UIEdgeInsets(top: 32, left: 32, bottom: 0, right: 32),
                                size: CGSize(width: 0, height: 24))

        descriptionLabel.setAnchor(top: subTitleLabel.bottomAnchor,
                                   leading: view.leadingAnchor,
                                   bottom: nil,
                                   trailing: view.trailingAnchor,
                                   padding: UIEdgeInsets(top: 24, left: 32, bottom: 0, right: 32))

        acceptButton.setAnchor(top: nil,
                               leading: view.leadingAnchor,
                               bottom: view.bottomAnchor,
                               trailing: view.trailingAnchor,
                               padding: UIEdgeInsets(top: 0, left: 32, bottom: 42, right: 32),
                               size: CGSize(width: 0, height: 48))

        linksLabel.setAnchor(top: nil,
                             leading: view.leadingAnchor,
                             bottom: acceptButton.topAnchor,
                             trailing: view.trailingAnchor,
                             padding: UIEdgeInsets(top: 0, left: 32, bottom: 32, right: 32))

        moreButton.setAnchor(top: titleLabel.topAnchor,
                             leading: titleLabel.trailingAnchor,
                             bottom: nil,
                             trailing: view.trailingAnchor,
                             padding: UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32),
                             size: CGSize(width: 32, height: 32))
    }

    // MARK: Actions
    @objc private func acceptPressed() {
        if let currentBuildVersion = Bundle.main.buildVersionNumber,
           let version = Int(currentBuildVersion) {
            LucaPreferences.shared.termsAcceptedVersion = version
        }

        self.dismiss(animated: true, completion: nil)
    }

    @objc private func morePressed() {
        let deleteAccountAction = UIAlertAction(title: L10n.Data.ResetData.title, style: .default) { (_) in
            DeleteAccountCoordinator(presenter: self).start()
        }

        let additionalActions = [deleteAccountAction]

        UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet).termsAndConditionsActionSheet(viewController: self, additionalActions: additionalActions)
    }

    // MARK: - Accessibility
    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header
        UIAccessibility.setFocusTo(titleLabel, notification: .layoutChanged, delay: 0.8)
    }
}

extension TermsAcceptanceViewController: NantesLabelDelegate {
    func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }
}
