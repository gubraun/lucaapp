import UIKit
import RxSwift

class HistoryViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leadingMargin: NSLayoutConstraint!
    @IBOutlet weak var dataAccessButtonView: UIView!

    var events: [HistoryEvent] = []

    var disposeBag: DisposeBag?
    let bottomGradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self

        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 25, left: 0, bottom: 75, right: 0)

        addBottomGradient()
        dataAccessButtonView.accessibilityLabel = L10n.History.Accessibility.dataAccessButton
        dataAccessButtonView.isAccessibilityElement = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

        UIAccessibility.setFocusTo(titleLabel)

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

    @IBAction func dataReleasePressed(_ sender: UIButton) {
        let alert = AlertViewControllerFactory.createDataAccessPickDaysViewController(confirmAction: presentDataAccessAlertController(withNumberOfDays:))
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overCurrentContext
        present(alert, animated: true, completion: nil)
    }

    @IBAction func deleteHistoryPressed(_ sender: UIButton) {
        resetLocallyAlert()
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
        }, viewController: self)
    }

    private func presentDataAccessAlertController(withNumberOfDays numberOfDays: Int) {
        let alert = AlertViewControllerFactory.createDataAccessConfirmationViewController(numberOfDays: numberOfDays, confirmAction: {
            self.dataAccessAlertConfirmAction(withNumberOfDays: numberOfDays)
        })
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overCurrentContext
        present(alert, animated: true, completion: nil)
    }

    private func dataAccessAlertConfirmAction(withNumberOfDays numberOfDays: Int) {
        let viewController = AlertViewControllerFactory.createTANReleaseViewController(withNumberOfDaysTransferred: numberOfDays)
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overCurrentContext
        self.present(viewController, animated: true, completion: nil)
    }

    func addBottomGradient() {
        bottomGradientLayer.frame = CGRect(x: leadingMargin.constant, y: tableView.frame.origin.y + tableView.frame.height - 100.0, width: tableView.bounds.width, height: 100.0)
        bottomGradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        self.view.layer.addSublayer(bottomGradientLayer)
    }

    private func reloadData() -> Completable {
        ServiceContainer.shared.history
            .removeOldEntries()
            .andThen(ServiceContainer.shared.history.historyEvents)
            .observeOn(MainScheduler.instance)
            .do(onSuccess: { entries in
                self.events = entries
                self.tableView.reloadData()
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
        let viewController = AlertViewControllerFactory.createPrivateMeetingInfoViewController(historyEvent: userEvent)
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overFullScreen
        self.present(viewController, animated: true, completion: nil)
    }

    func showUserTransferInfoViewController(withNumberOfDays numberOfDays: Int) {
        let viewController = AlertViewControllerFactory.createInfoViewController(titleText: L10n.Data.Shared.title, descriptionText: L10n.Data.Shared.description(numberOfDays))
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overFullScreen
        self.present(viewController, animated: true, completion: nil)
    }

}
