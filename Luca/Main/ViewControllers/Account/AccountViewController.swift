import UIKit

struct AccountOption {
    let title: String
    let coordinator: Coordinator
}

class AccountViewController: UIViewController {

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = L10n.Navigation.Tab.account
        titleLabel.font = UIFont.montserratViewControllerTitle
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        return titleLabel
    }()

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
        tableView.alwaysBounceVertical = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))  // remove last separator
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AccountTableViewCell.classForCoder(), forCellReuseIdentifier: "AccountTableViewCell")
        view.addSubview(tableView)

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
                 AccountOption(title: L10n.WelcomeViewController.gitLab, coordinator: OpenLinkCoordinator(url: L10n.WelcomeViewController.linkGitLab))]]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContraints()

        // child VCs show back button without button title
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        self.navigationController?.setTranslucent()
        self.navigationController?.navigationBar.tintColor = .white
        setupAccessibility()

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupContraints() {
        titleLabel.setAnchor(top: view.topAnchor,
                             leading: view.leadingAnchor,
                             bottom: nil,
                             trailing: view.trailingAnchor,
                             padding: UIEdgeInsets(top: 42, left: 32, bottom: 0, right: 32))
        titleLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true

        spacerView.setAnchor(top: titleLabel.bottomAnchor,
                             leading: view.leadingAnchor,
                             bottom: nil,
                             trailing: view.trailingAnchor,
                             padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        spacerView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        tableView.setAnchor(top: spacerView.bottomAnchor,
                            leading: view.leadingAnchor,
                            bottom: view.bottomAnchor,
                            trailing: view.trailingAnchor,
                            padding: UIEdgeInsets(top: 32, left: 32, bottom: 0, right: 32))
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
        titleLabel.accessibilityTraits = .header
        UIAccessibility.setFocusTo(titleLabel, notification: .layoutChanged, delay: 0.8)
    }

}
