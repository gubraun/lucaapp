import UIKit

struct AccountOption {
    let title: String
    let coordinator: Coordinator
}

class AccountViewController: UIViewController {

    private lazy var spacerView: UIView = {
        let spacerView = UIView()
        spacerView.backgroundColor = .lucaGrey
        view.addSubview(spacerView)

        return spacerView
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorColor = .lucaDarkGrey
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 32, right: 0)
        tableView.alwaysBounceVertical = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))  // remove last separator
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AccountTableViewCell.classForCoder(), forCellReuseIdentifier: "AccountTableViewCell")
        view.addSubview(tableView)
        tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)

        return tableView
    }()

    private lazy var options: [[AccountOption]] = {
        return [[AccountOption(title: L10n.UserData.Navigation.edit, coordinator: EditAccountCoordinator(presenter: self)),
                 AccountOption(title: L10n.Data.ResetData.title, coordinator: DeleteAccountCoordinator(presenter: self))],
                [AccountOption(title: L10n.General.faq, coordinator: OpenLinkCoordinator(url: L10n.WelcomeViewController.linkFAQ)),
                 AccountOption(title: L10n.General.support, coordinator: SendSupportEmailCoordinator(presenter: self)),
                 AccountOption(title: L10n.General.dataPrivacy, coordinator: OpenLinkCoordinator(url: L10n.WelcomeViewController.linkPrivacyPolicy)),
                 AccountOption(title: L10n.General.termsAndConditions, coordinator: OpenLinkCoordinator(url: L10n.WelcomeViewController.linkTC)),
                 AccountOption(title: L10n.General.healthDepartmentKey, coordinator: HealthDepartmentCryptoInfoCoordinator(presenter: self)),
                 AccountOption(title: L10n.General.imprint, coordinator: OpenLinkCoordinator(url: L10n.General.linkImprint)),
                 AccountOption(title: L10n.acknowledgements, coordinator: LicensesCoordinator(presenter: self)),
                 AccountOption(title: L10n.WelcomeViewController.gitLab, coordinator: GitlabLinkCoordinator(presenter: self, url: L10n.WelcomeViewController.linkGitLab)),
                 AccountOption(title: L10n.AppVersion.button, coordinator: VersionDetailsCoordinator(presenter: self))]]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationbar()
        setupContraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAccessibility()
    }

}

extension AccountViewController {
    private func setupNavigationbar() {
        set(title: L10n.Navigation.Tab.account)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    private func setupContraints() {
        spacerView.setAnchor(top: view.topAnchor,
                             leading: view.leadingAnchor,
                             bottom: nil,
                             trailing: view.trailingAnchor,
                             padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        spacerView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        tableView.setAnchor(top: spacerView.bottomAnchor,
                            leading: view.leadingAnchor,
                            bottom: view.bottomAnchor,
                            trailing: view.trailingAnchor,
                            padding: UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32))
    }
}

extension AccountViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options[section].capacity
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! AccountTableViewCell
        cell.accessibilityTraits = .button
        cell.configureTitle(options[indexPath.section][indexPath.row].title)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}

extension AccountViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        options[indexPath.section][indexPath.row].coordinator.start()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 24 : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cornerRadius = 4
        var corners: UIRectCorner = []

        if indexPath.row == 0 {
            corners.update(with: .topLeft)
            corners.update(with: .topRight)
        }

        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            corners.update(with: .bottomLeft)
            corners.update(with: .bottomRight)
        }

        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: cell.bounds,
                                      byRoundingCorners: corners,
                                      cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
        cell.layer.mask = maskLayer
    }
}

// MARK: - Accessibility
extension AccountViewController {
    private func setupAccessibility() {
        guard let navigationbarTitleLabel = navigationbarTitleLabel else { return }
        navigationbarTitleLabel.accessibilityTraits = .header
        UIAccessibility.setFocusTo(navigationbarTitleLabel, notification: .layoutChanged, delay: 0.8)
    }
}
