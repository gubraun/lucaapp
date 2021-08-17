import Foundation

protocol Vaccination: Document, AssociableToIdentity, ContainsDateOfBirth {

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
}

extension Vaccination {
    var identifier: Int {
        guard let payloadData = originalCode.data(using: .utf8) else {
            return -1
        }
        return Int(payloadData.crc32)
    }

    var vaccinatedSinceDays: Int {
        return Calendar.current.dateComponents([.day], from: self.date, to: Date()).day ?? Int.max
    }

    var fullyVaccinatedInDays: Int {
        return 14 - vaccinatedSinceDays
    }

    var hasAllDosesReceived: Bool {
        return doseNumber == dosesTotalNumber
    }

    func isComplete() -> Bool {
        let dateIsValid = vaccinatedSinceDays > 14
        return hasAllDosesReceived && dateIsValid
    }

    var expiresAt: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: date) ?? date
    }
}
