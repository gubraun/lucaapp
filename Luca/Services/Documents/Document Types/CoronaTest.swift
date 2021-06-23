import Foundation
import RxSwift
import SwiftJWT

public typealias TestClaims = Codable & Claims

protocol CoronaTest: Document {

    /// Encoded QR code
    var originalCode: String { get set }

    /// test date
    var date: Date { get }

    /// test type e.g. PCR
    var testType: String { get }

    /// testing laboratory
    var laboratory: String { get }

    /// testing doctor
    var doctor: String { get }

    /// check if test result is negative
    var isNegative: Bool { get }

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
}
