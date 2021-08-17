import Foundation
import RxSwift
import SwiftJWT

protocol AssociableToIdentity {
    func belongsToUser(withFirstName: String, lastName: String) -> Bool
}

public typealias TestClaims = Codable & Claims
public typealias TestClaimsWithFingerprint = Codable & ClaimsWithFingerprint

protocol CoronaTest: Document, AssociableToIdentity {

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

    /// check if positive test is valid (if it is a positive PCR test over 14 days)
    var isValidPositive: Bool { get }

    /// test provider
    var provider: String { get }

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
        var unit: Calendar.Component = .hour
        switch testType {
        case .pcr:
            validity = isNegative ? 72 : 6
            unit = isNegative ? .hour : .month
        case .fast:
            validity = 48
        case .other:
            validity = 48
        }
        return Calendar.current.date(byAdding: unit, value: validity, to: date) ?? date
    }

    func isValid() -> Single<Bool> {
        Single.from { Date() < self.expiresAt }
    }

    var isValidPositive: Bool {
        guard testType == .pcr, !isNegative else {
            return false
        }

        if let validityFrom = Calendar.current.date(byAdding: .day, value: 14, to: date) {
            return Date() > validityFrom
        }
        return false
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
