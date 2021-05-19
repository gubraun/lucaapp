import Foundation
import RxSwift
import SwiftJWT

public typealias TestClaims = Codable & Claims

protocol CoronaTest {

    /// Encoded QR code
    var originalCode: String { get set }

    /// test date
    var date: Date { get }

    /// test type e.g. PCR
    var testType: String { get }

    /// testing laboratory
    var laboratory: String { get }

    /// check if test result is negative
    var isNegative: Bool { get }

    /// RealmDataModel identifier for CoronaTestPayload objects
    var identifier: Int? { get set }

    /// Name check
    /// - Parameters:
    ///   - firstName: first name in app
    ///   - lastName: last name in app
    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool

    /// test validation
    func isValid() -> Single<Bool>

    /// Parse URL to test object
    /// - Parameter parse: URL string from QR code
    static func decodeTestCode(parse: String) -> Single<CoronaTest>
}
