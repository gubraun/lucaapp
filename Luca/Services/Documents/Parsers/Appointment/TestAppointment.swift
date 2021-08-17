import UIKit

struct TestAppointmentPayload: Codable {
    var timestamp: String
    var type: String
    var lab: String
    var address: String
    var qrCode: String
}

class TestAppointment: Appointment {
    var originalCode: String

    var hashSeed: String { originalCode }

    var timestamp: Int

    var type: String

    var lab: String

    var address: String

    var qrCode: String

    var expiresAt: Date {
        Calendar.current.date(byAdding: .hour, value: 2, to: Date(timeIntervalSince1970: Double(timestamp))) ?? Date()
    }

    init(payload: TestAppointmentPayload, originalCode: String) {
        self.originalCode = originalCode
        self.timestamp = Int(payload.timestamp) ?? 0
        self.type = payload.type
        self.lab = payload.lab
        self.address = payload.address
        self.qrCode = payload.qrCode
    }
}
