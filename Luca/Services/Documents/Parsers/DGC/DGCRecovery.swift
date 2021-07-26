import UIKit

struct DGCRecovery: Recovery & DocumentCellViewModel {
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var validFromDate: Date
    var validUntilDate: Date
    var originalCode: String
    var issuer: String
    var laboratory: String { issuer }

    init(cert: DGCCert, recovery: DGCRecoveryEntry, originalCode: String) {
        self.firstName = cert.firstName
        self.lastName = cert.lastName
        self.dateOfBirth = cert.dateOfBirth
        self.validFromDate = recovery.validFrom
        self.validUntilDate = recovery.validUntil
        self.issuer = recovery.issuer
        self.originalCode = originalCode
    }

    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool {
        let uppercaseAppFullname = (firstName + lastName).uppercased()
        let uppercaseTestFullname = (self.firstName + self.lastName).uppercased()
        return uppercaseAppFullname == uppercaseTestFullname
    }

    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, delegate: DocumentCellDelegate) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "CoronaRecoveryTableViewCell", for: indexPath) as! CoronaRecoveryTableViewCell
        cell.recovery = self
        cell.delegate = delegate

        return cell
    }
}
