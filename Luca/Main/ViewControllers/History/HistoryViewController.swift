import UIKit
import RxSwift

class HistoryViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var events: [HistoryEvent] = []
    
    var disposeBag: DisposeBag?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 25, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        ServiceContainer.shared.history.removeOldEntries()
        events = ServiceContainer.shared.history.historyEvents
        
        tableView.reloadData()
        
        let newDisposeBag = DisposeBag()
        
        ServiceContainer.shared.history
            .onEventAddedRx
            .observeOn(MainScheduler.instance)
            .do(onNext: { _ in
                self.events = ServiceContainer.shared.history.historyEvents
                self.tableView.reloadData()
            })
            .subscribe()
            .disposed(by: newDisposeBag)
        self.disposeBag = newDisposeBag
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
        
        disposeBag = nil
    }
    
    @IBAction func viewMorePressed(_ sender: UITapGestureRecognizer) {
        let resetLocallyAction = UIAlertAction(title: L10n.Data.Clear.title, style: .default) { (_) in
            self.resetLocallyAlert()
        }
        
        let additionalActions = [resetLocallyAction]
        
        UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
            .menuActionSheet(viewController: self, additionalActions: additionalActions)
    }
    
    @IBAction func dataReleasePressed(_ sender: UIButton) {
        UIAlertController(title: L10n.History.Alert.title, message: L10n.History.Alert.description, preferredStyle: .alert).yesActionAndNoAlert(action: alertYesAction, viewController: self)
    }
    
    func resetLocallyAlert() {
        UIAlertController(title: L10n.Data.Clear.title, message: L10n.Data.Clear.description, preferredStyle: .alert).actionAndCancelAlert(actionText: L10n.Data.Clear.title, action: {
            DataResetService.resetHistory()
            self.events = ServiceContainer.shared.history.historyEvents
            self.tableView.reloadData()
        }, viewController: self)
    }
    
    func alertYesAction() {
        let viewController = AlertViewControllerFactory.createTANReleaseViewController()
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overCurrentContext
        self.present(viewController, animated: true, completion: nil)
    }
    
}
extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath) as! HistoryTableViewCell
        
        // Show checkins in reverse order
        let event = events[events.count - indexPath.row - 1]
        cell.setup(historyEvent: event)
        if let userEvent = event as? UserEvent, userEvent.checkin.role == .host {
            cell.infoPressedActionHandler = {
                let viewController = AlertViewControllerFactory.createPrivateMeetingInfoViewController(historyEvent: userEvent)
                viewController.modalTransitionStyle = .crossDissolve
                viewController.modalPresentationStyle = .overFullScreen
                self.present(viewController, animated: true, completion: nil)
            }
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
    
}
