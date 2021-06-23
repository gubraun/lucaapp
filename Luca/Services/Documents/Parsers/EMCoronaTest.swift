import Foundation
import SwiftJWT

struct EMCoronaTest: JWTTest {

    var version: Int
    var name: String
    var time: Int
    var category: Category
    var result: Result
    var lab: String
    var doctor: String
    var originalCode: String

    var isNegative: Bool {
        // EM Codes are always true
        return true
    }

    init(claims: JWTTestClaims, originalCode: String) {
        self.version = claims.version
        self.name = claims.name
        self.time = claims.time
        self.category = claims.category
        self.result = claims.result
        self.lab = claims.lab
        self.doctor = claims.doctor
        self.originalCode = originalCode
    }

}

extension EMCoronaTest {

    var game: String {
        return doctor
    }

    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, delegate: DocumentCellDelegate) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "EMTestTableViewCell", for: indexPath) as! EMTestTableViewCell
        cell.coronaTest = self
        cell.delegate = delegate

        return cell
    }

}
