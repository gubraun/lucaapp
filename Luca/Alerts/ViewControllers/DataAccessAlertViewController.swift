import UIKit

class DataAccessAlertViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    var newDataAccesses: [HealthDepartment: [(TraceInfo, Location)]] = [:]
    var newDataAccessesArray: [(department: HealthDepartment, infos: [(traceInfo: TraceInfo, location: Location)])] = []
    var allAccessesPressed: (() -> ())?
    
    private let tableViewHeightConstraint: CGFloat = 100.0

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        newDataAccessesArray = Array(zip(newDataAccesses.keys, newDataAccesses.values))
        tableView.register(NewDataAccessHeaderView.self, forHeaderFooterViewReuseIdentifier: "NewDataAccessHeaderView")
        tableView.reloadData()
        setupTableViewHeight()
    }
    
    func setupTableViewHeight() {
        let rowCount = newDataAccesses.values.map { $0.count }.reduce(0, +)
        tableViewHeight.constant = CGFloat(rowCount) * tableViewHeightConstraint +
                                   CGFloat(newDataAccesses.keys.count) * tableView.sectionHeaderHeight +
                                   CGFloat(newDataAccesses.keys.count) * tableView.sectionFooterHeight
    }

    @IBAction func closePressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func allDataAccessesPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: allAccessesPressed ?? nil)
    }
    
}
extension DataAccessAlertViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return newDataAccessesArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newDataAccessesArray[section].infos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewDataAccessTableViewCell", for: indexPath) as! NewDataAccessTableViewCell
        let newDataAccess = newDataAccessesArray[indexPath.section].infos[indexPath.row]
        
        cell.locationLabel.text = newDataAccess.location.name
        let checkin = newDataAccess.traceInfo.checkInDate
        if let checkout = newDataAccess.traceInfo.checkOutDate {
            cell.dateLabel.text = "\(checkin.formattedDate) - \(checkout.formattedDate)"
        } else {
            cell.dateLabel.text = "\(checkin.formattedDate)"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableViewHeightConstraint
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "NewDataAccessHeaderView") as! NewDataAccessHeaderView
        view.departmentLabel.text = newDataAccessesArray[section].department.name
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }
    
}
