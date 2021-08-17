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
    case unknown

    public init(from decoder: Decoder) throws {
        self = try Result(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }

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

protocol JWTTest: CoronaTest {

    var version: Int { get }
    var name: String { get }
    var time: Int { get }
    var category: Category { get }
    var result: Result { get }
    var lab: String { get }

}

extension JWTTest {

    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(time))
    }

    var testType: CoronaTestType {
        switch category {
        case .fast:
            return .fast
        case .pcr:
            return .pcr
        case .other, .unknown:
            return .other
        }
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

    var hashSeed: String {

        // use only the first two parts of the original code
        // and remove all whitespaces
        originalCode
            .filter { !$0.isWhitespace }
            .split(separator: ".")
            .prefix(2)
            .joined(separator: ".")
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
    var provider: String

    init(claims: JWTTestClaims, originalCode: String, provider: String) {
        self.version = claims.version
        self.name = claims.name
        self.time = claims.time
        self.category = claims.category
        self.result = claims.result
        self.lab = claims.lab
        self.doctor = claims.doctor
        self.originalCode = originalCode
        self.provider = provider
    }
}
