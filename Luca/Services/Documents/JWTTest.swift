import Foundation
import RxSwift
import SwiftJWT

public protocol ClaimsWithFingerprint: Claims {

    /// Fingerprint
    var f: String? { get }
}

struct JWTTestClaims: TestClaimsWithFingerprint {

    var version: Int
    var name: String
    var time: Int
    var category: Category
    var result: Result
    var lab: String
    var doctor: String
    var f: String?

    enum CodingKeys: String, CodingKey {
        case version = "v"
        case name = "n"
        case time = "t"
        case category = "c"
        case result = "r"
        case lab = "l"
        case doctor = "d"
        case f = "f"
    }

}

enum Result: String, Codable {

    case positive = "p"
    case negative = "n"

    var isNegative: Bool {
        switch self {
        case .negative: return true
        default: return false
        }
    }
}

enum Category: String, Codable {

    case fast = "f"
    case pcr = "p"
    case other = "o"
    case unknown

    public init(from decoder: Decoder) throws {
        self = try Category(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }

    var category: String {
        switch self {
        case .fast: return L10n.Test.Result.fast
        case .pcr: return L10n.Test.Result.pcr
        default: return L10n.Test.Result.other
        }
    }
}

protocol JWTTest: CoronaTest & DocumentCellViewModel {

    var version: Int { get }
    var name: String { get }
    var time: Int { get }
    var category: Category { get }
    var result: Result { get }
    var lab: String { get }

}

extension JWTTest {
    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, delegate: DocumentCellDelegate) -> UITableViewCell {

        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "CoronaTestTableViewCell", for: indexPath) as! CoronaTestTableViewCell
        cell.coronaTest = self
        cell.delegate = delegate

        return cell
    }
}

extension JWTTest {

    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(time))
    }

    var testType: String {
        return category.category
    }

    var laboratory: String {
        return lab
    }

    var isNegative: Bool {
        return result.isNegative
    }

    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool {
        let uppercaseFullname = (firstName + lastName).uppercased()
        let onlyAsciiName = uppercaseFullname.components(separatedBy: CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted).joined()
        let nameHash = onlyAsciiName.sha256()
        return nameHash == name
    }

    func isValid() -> Single<Bool> {
        Single.create { observer -> Disposable in
            let validity = category == .pcr ? 72.0 : 48.0
            let dateIsValid = TimeInterval(time) + TimeUnit.hour(amount: validity).timeInterval > Date().timeIntervalSince1970
            observer(.success(dateIsValid))

            return Disposables.create()
        }
    }
}

struct JWTTestPayload: JWTTest {

    var version: Int
    var name: String
    var time: Int
    var category: Category
    var result: Result
    var lab: String
    var doctor: String
    var originalCode: String

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
