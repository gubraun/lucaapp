import Foundation
import RxSwift
import SwiftJWT

protocol Vaccination: Document {

    /// Encoded QR code
    var originalCode: String { get set }

    /// last vaccination date
    var date: Date { get }

    /// user date of birth
    var dateOfBirth: Date { get }

    /// test type e.g. PCR
    var vaccineType: String { get }

    var doseNumber: Int { get }

    var dosesTotalNumber: Int { get }

    /// testing laboratory
    var laboratory: String { get }

    /// Name check
    /// - Parameters:
    ///   - firstName: first name in app
    ///   - lastName: last name in app
    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool
}

extension Vaccination {
    var identifier: Int {
        guard let payloadData = originalCode.data(using: .utf8) else {
            return -1
        }
        return Int(payloadData.crc32)
    }

    func isComplete() -> Bool {
        let allDosesReceived = doseNumber == dosesTotalNumber
        let differenceDays = Calendar.current.dateComponents([.day], from: self.date, to: Date()).day ?? Int.max
        let dateIsValid = differenceDays > 14

        return allDosesReceived && dateIsValid
    }
}
