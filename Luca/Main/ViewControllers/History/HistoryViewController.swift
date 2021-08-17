import UIKit
import RxSwift

class HistoryViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leadingMargin: NSLayoutConstraint!
    @IBOutlet weak var dataAccessButton: UIButton!
    @IBOutlet weak var shareHistoryButton: UIButton!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var viewMoreButton: UIButton!

    var events: [HistoryEvent] = []

    var disposeBag: DisposeBag?
    let bottomGradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self

        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 25, left: 0, bottom: 75, right: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        setupAccessibility()

        let newDisposeBag = DisposeBag()

        ServiceContainer.shared.history.onEventAddedRx
            .observe(on: MainScheduler.instance)
            .flatMap { _ in self.reloadData() }
            .subscribe()
            .disposed(by: newDisposeBag)

        reloadData()
            .subscribe()
            .disposed(by: newDisposeBag)

        self.disposeBag = newDisposeBag
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)

        disposeBag = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomGradientLayer.frame = CGRect(x: leadingMargin.constant, y: tableView.frame.origin.y + tableView.frame.height - 100.0, width: tableView.bounds.width, height: 100.0)
    }

    @IBAction func dataAccessPressed(_ sender: UIButton) {
        let vc = ViewControllerFactory.Main.createDataAccessViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func dataReleasePressed(_ sender: UIButton) {
        let alert = ViewControllerFactory.Alert.createDataAccessPickDaysViewController(confirmAction: presentDataAccessAlertController(withNumberOfDays:))
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }

    @IBAction func moreMenuPressed(_ sender: UIButton) {
        let deleteAction = UIAlertAction(title: L10n.Data.Clear.title, style: .default) { _ in
            self.resetLocallyAlert()
        }

        UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet).menuActionSheet(viewController: self, additionalActions: [deleteAction])
    }

    func setupViews() {
        tableView.isHidden = events.isEmpty
        shareHistoryButton.isHidden = events.isEmpty
        emptyStateView.isHidden = !events.isEmpty
        events.isEmpty ? removeBottomGradient() : addBottomGradient()
        setupAccessibilityElements(isEmpty: events.isEmpty)
    }

    func resetLocallyAlert() {
        UIAlertController(
            title: L10n.Data.Clear.title,
            message: L10n.Data.Clear.description,
            preferredStyle: .alert
        )
        .actionAndCancelAlert(actionText: L10n.Data.Clear.title, action: {
            DataResetService.resetHistory()
            self.events = []
            self.tableView.reloadData()
            self.setupViews()
        }, viewController: self)
    }

    private func presentDataAccessAlertController(withNumberOfDays numberOfDays: Int) {
        let alert = ViewControllerFactory.Alert.createDataAccessConfirmationViewController(numberOfDays: numberOfDays, confirmAction: {
            self.dataAccessAlertConfirmAction(withNumberOfDays: numberOfDays)
        })
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }

    private func dataAccessAlertConfirmAction(withNumberOfDays numberOfDays: Int) {
        let viewController = ViewControllerFactory.Alert.createTANReleaseViewController(withNumberOfDaysTransferred: numberOfDays)
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overFullScreen
        self.present(viewController, animated: true, completion: nil)
    }

    func addBottomGradient() {
        bottomGradientLayer.frame = CGRect(x: leadingMargin.constant, y: tableView.frame.origin.y + tableView.frame.height - 100.0, width: tableView.bounds.width, height: 100.0)
        bottomGradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        self.view.layer.addSublayer(bottomGradientLayer)
    }

    func removeBottomGradient() {
        bottomGradientLayer.removeFromSuperlayer()
    }

    private func reloadData() -> Completable {
        ServiceContainer.shared.history
            .removeOldEntries()
            .andThen(ServiceContainer.shared.history.historyEvents)
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { entries in
                self.events = entries
                self.tableView.reloadData()
                self.setupViews()
            })
            .asObservable()
            .ignoreElementsAsCompletable()
    }

}
extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath) as! HistoryTableViewCell

        // Show events in reverse order
        let event = events[events.count - indexPath.row - 1]
        cell.setup(historyEvent: event)
        if let userEvent = event as? UserEvent, userEvent.checkin.role == .host {
            cell.infoPressedActionHandler = { self.showPrivateMeetingInfoViewController(userEvent: userEvent) }
        }

        if let userDataTransfer = event as? UserDataTransfer {
            cell.infoPressedActionHandler = {
                let numberOfDays = userDataTransfer.entry.numberOfDaysShared ?? 14
                self.showUserTransferInfoViewController(withNumberOfDays: numberOfDays) }
        }

        if events.count == 1 {
            cell.setupHistoryLineViews(position: .only)
        } else if indexPath.row == events.count - 1 {
            cell.setupHistoryLineViews(position: .last)
        } else if indexPath.row == 0 {
            cell.setupHistoryLineViews(position: .first)
        }

        return cell
    }

    func showPrivateMeetingInfoViewController(userEvent: UserEvent) {
        let viewController = ViewControllerFactory.Alert.createPrivateMeetingInfoViewController(historyEvent: userEvent)
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overFullScreen
        self.present(viewController, animated: true, completion: nil)
    }

    func showUserTransferInfoViewController(withNumberOfDays numberOfDays: Int) {
        let viewController = ViewControllerFactory.Alert.createInfoViewController(titleText: L10n.Data.Shared.title, descriptionText: L10n.Data.Shared.description(numberOfDays))
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overFullScreen
        self.present(viewController, animated: true, completion: nil)
    }

}

// MARK: - Accessibility
extension HistoryViewController {

    private func setupAccessibility() {
        dataAccessButton.accessibilityLabel = L10n.History.Accessibility.dataAccessButton
        viewMoreButton.accessibilityLabel = L10n.Navigation.menu
        titleLabel.accessibilityTraits = .header
        UIAccessibility.setFocusTo(titleLabel, notification: .layoutChanged, delay: 0.8)
    }

    private func setupAccessibilityElements(isEmpty: Bool) {
        let emptyStateElements = [titleLabel, dataAccessButton, viewMoreButton, emptyStateView].map { $0 as Any }
        let elements = [titleLabel, dataAccessButton, viewMoreButton, tableView, shareHistoryButton].map { $0 as Any }
        self.view.accessibilityElements = isEmpty ? emptyStateElements : elements
    }

}
