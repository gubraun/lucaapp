import Foundation
import RxSwift
import SwiftJWT

public typealias TestClaims = Codable & Claims
public typealias TestClaimsWithFingerprint = Codable & ClaimsWithFingerprint

protocol CoronaTest: Document {

    /// Encoded QR code
    var originalCode: String { get set }

    /// test date
    var date: Date { get }

    /// test type e.g. PCR
    var testType: CoronaTestType { get }

    /// testing laboratory
    var laboratory: String { get }

    /// testing doctor
    var doctor: String { get }

    /// check if test result is negative
    var isNegative: Bool { get }

    /// test provider
    var provider: String { get }

    /// Name check
    /// - Parameters:
    ///   - firstName: first name in app
    ///   - lastName: last name in app
    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool

    /// test validation
    func isValid() -> Single<Bool>

}

extension CoronaTest {
    var identifier: Int {
        guard let payloadData = originalCode.data(using: .utf8) else {
            return -1
        }
        return Int(payloadData.crc32)
    }

    var expiresAt: Date {
        let validity: Int
        switch testType {
        case .pcr:
            validity = 72
        case .fast:
            validity = 48
        case .other:
            validity = 48
        }
        return Calendar.current.date(byAdding: .hour, value: validity, to: date) ?? date
    }

    func isValid() -> Single<Bool> {
        Single.from { Date() < self.expiresAt }
    }
}

enum CoronaTestType {
    case pcr
    case fast
    case other
}

extension CoronaTestType {
    var localized: String {
        switch self {
        case .pcr:
            return L10n.Test.Result.pcr
        case .fast:
            return L10n.Test.Result.fast
        case .other:
            return L10n.Test.Result.other
        }
    }
}
