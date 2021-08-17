import Foundation

protocol Recovery: Document {

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

    /// Name check
    /// - Parameters:
    ///   - firstName: first name in app
    ///   - lastName: last name in app
    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool
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
