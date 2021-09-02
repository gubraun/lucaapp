import UIKit
import RxSwift

class HistoryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leadingMargin: NSLayoutConstraint!
    @IBOutlet weak var shareHistoryButton: UIButton!
    @IBOutlet weak var emptyStateView: UIView!

    var dataAccessButton: UIBarButtonItem!
    var viewMoreButton: UIBarButtonItem!

    var events: [HistoryEvent] = []

    var disposeBag: DisposeBag?
    let bottomGradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationbar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
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
}

// MARK: - Setup

extension HistoryViewController {
    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressOnEvent(sender:)))
        tableView.addGestureRecognizer(longPressRecognizer)

        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 25, left: 0, bottom: 75, right: 0)

    }

    private func setupNavigationbar() {
        set(title: L10n.Navigation.Tab.history)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        dataAccessButton = UIBarButtonItem(image: Asset.viewMore.image, style: .plain, target: self, action: #selector(moreMenuPressed))
        viewMoreButton = UIBarButtonItem(image: Asset.eye.image, style: .plain, target: self, action: #selector(dataAccessPressed))

        navigationItem.rightBarButtonItems = [ dataAccessButton, viewMoreButton ]
    }

    private func setupViews() {
        tableView.isHidden = events.isEmpty
        shareHistoryButton.isHidden = events.isEmpty
        emptyStateView.isHidden = !events.isEmpty
        events.isEmpty ? removeBottomGradient() : addBottomGradient()
        setupAccessibilityElements(isEmpty: events.isEmpty)
    }
}

// MARK: - Actions

extension HistoryViewController {
    @objc
    func dataAccessPressed() {
        let viewController = ViewControllerFactory.Main.createDataAccessViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    @IBAction func dataReleasePressed(_ sender: UIButton) {
        let alert = ViewControllerFactory.Alert.createDataAccessPickDaysViewController(confirmAction: presentDataAccessAlertController(withNumberOfDays:))
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }

    @objc
    func moreMenuPressed() {
        let deleteAction = UIAlertAction(title: L10n.Data.Clear.title, style: .default) { _ in
            self.resetLocallyAlert()
        }

        UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet).menuActionSheet(viewController: self, additionalActions: [deleteAction])
    }

    @objc
    private func didLongPressOnEvent(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if let event = eventForIndexPath(at: indexPath) as? UserEvent,
                   let traceId = event.checkin.traceInfo?.traceId {
                    let traceIdDescription = L10n.History.TraceId.pasteboard(traceId)
                    UIPasteboard.general.string = traceIdDescription
                    let alert = UIAlertController.infoAlert(title: "", message: L10n.History.TraceId.Alert.description(traceIdDescription))
                    present(alert, animated: true, completion: nil)
                }
            }
        }
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

        let event = eventForIndexPath(at: indexPath)
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

    private func eventForIndexPath(at indexPath: IndexPath) -> HistoryEvent {
        // Show events in reverse order
        return events[events.count - indexPath.row - 1]
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

        guard let navigationbarTitleLabel = navigationbarTitleLabel else { return }
        navigationbarTitleLabel.accessibilityTraits = .header
        UIAccessibility.setFocusTo(navigationbarTitleLabel, notification: .layoutChanged, delay: 0.8)
    }

    private func setupAccessibilityElements(isEmpty: Bool) {
        let emptyStateElements = [navigationbarTitleLabel, dataAccessButton, viewMoreButton, emptyStateView].map { $0 as Any }
        let elements = [navigationbarTitleLabel, dataAccessButton, viewMoreButton, tableView, shareHistoryButton].map { $0 as Any }
        self.view.accessibilityElements = isEmpty ? emptyStateElements : elements
    }

}
