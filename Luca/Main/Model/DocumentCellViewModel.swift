import UIKit

typealias TestCellViewModel = CoronaTest & DocumentCellViewModel

protocol DocumentCellViewModel {
    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, test: CoronaTest, delegate: DocumentCellDelegate) -> UITableViewCell
}

extension DocumentCellViewModel {
    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, test: CoronaTest, delegate: DocumentCellDelegate) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "CoronaTestTableViewCell", for: indexPath) as! CoronaTestTableViewCell
        cell.coronaTest = test
        cell.delegate = delegate

        return cell
    }
}
