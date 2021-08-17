import Foundation

protocol Recovery: Document, AssociableToIdentity, ContainsDateOfBirth {

    /// Encoded QR code
    var originalCode: String { get set }

    /// issue date
    var validFromDate: Date { get }

    /// expiration date
    var validUntilDate: Date { get }

    /// testing laboratory
    var laboratory: String { get }

    /// user date of birth
    var dateOfBirth: Date { get }
}

extension Recovery {
    var identifier: Int {
        guard let payloadData = originalCode.data(using: .utf8) else {
            return -1
        }
        return Int(payloadData.crc32)
    }

    /// recovery validation
    func isValid() -> Bool {
        return Date() < validUntilDate
    }

    var expiresAt: Date { validUntilDate }
}
