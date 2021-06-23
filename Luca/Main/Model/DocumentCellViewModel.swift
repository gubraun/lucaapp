import UIKit

protocol DocumentCellViewModel {
    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, delegate: DocumentCellDelegate) -> UITableViewCell
}

extension DocumentCellViewModel {
    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, delegate: DocumentCellDelegate) -> UITableViewCell {

        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "CoronaTestTableViewCell", for: indexPath) as! CoronaTestTableViewCell
        cell.coronaTest = self as? CoronaTest
        cell.delegate = delegate

        return cell
    }
}
