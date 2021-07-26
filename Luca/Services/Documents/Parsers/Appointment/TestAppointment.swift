import UIKit

struct TestAppointmentPayload: Codable {
    var timestamp: String
    var type: String
    var lab: String
    var address: String
    var qrCode: String
}

class TestAppointment: Appointment & DocumentCellViewModel {
    var originalCode: String

    var timestamp: Int

    var type: String

    var lab: String

    var address: String

    var qrCode: String

    init(payload: TestAppointmentPayload, originalCode: String) {
        self.originalCode = originalCode
        self.timestamp = Int(payload.timestamp) ?? 0
        self.type = payload.type
        self.lab = payload.lab
        self.address = payload.address
        self.qrCode = payload.qrCode
    }

    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, delegate: DocumentCellDelegate) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppointmentTableViewCell", for: indexPath) as! AppointmentTableViewCell
        cell.appointment = self
        cell.delegate = delegate

        return cell
    }
}
