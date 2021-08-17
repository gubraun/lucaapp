import Foundation

protocol Appointment: Document {

    /// Encoded QR code
    var originalCode: String { get set }

    /// time of the appointment in milliseconds
    var timestamp: Int { get }

    /// appointment type
    var type: String { get }

    /// testing laboratory
    var lab: String { get }

    /// lab address
    var address: String { get }

    /// qr code
    var qrCode: String { get }
}

extension Appointment {
    var identifier: Int {
        guard let payloadData = originalCode.data(using: .utf8) else {
            return -1
        }
        return Int(payloadData.crc32)
    }

    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(timestamp/1000))
    }

    var expiresAt: Date {
        /// Appointment is valid until 2h after initial timestamp
        date.addingTimeInterval(TimeInterval((timestamp/1000) + (2 * 60 * 60)))
    }

    /// recovery validation
    func isValid() -> Bool {
        return Date() < expiresAt
    }
}
