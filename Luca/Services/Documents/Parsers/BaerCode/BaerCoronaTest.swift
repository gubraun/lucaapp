import Foundation
import RxSwift
import SwiftJWT
import SwiftCBOR

class BaerCodeParser: DocumentParser {
    func parse(code: String) -> Single<Document> {
        // Remove URL if present
        var parameters = code
        if let index = code.firstIndex(of: "#") {
            parameters = String(code.suffix(from: index))
            parameters.removeFirst()
        }

        return BaerCodeDecoder().decodeCode(parameters).debug("BAER CODE TEST").map { $0 as Document }
    }
}

enum BaerCodeType: Int, Codable {

    case fast = 1
    case pcr = 2
    case cormirnaty = 3
    case janssen = 4
    case moderna = 5
    case vaxzevria = 6

    var category: String {
        switch self {
        case .fast: return L10n.Test.Result.fast
        case .pcr: return L10n.Test.Result.pcr
        case .cormirnaty: return L10n.Vaccine.Result.cormirnaty
        case .janssen: return L10n.Vaccine.Result.janssen
        case .moderna: return L10n.Vaccine.Result.moderna
        case .vaxzevria: return L10n.Vaccine.Result.vaxzevria
        }
    }
}

enum BaerCodeVaccineState: Int {

    case firstVaccine = 1
    case secondPending = 2
    case complete = 3
}

struct BaerCoronaProcedure: Codable {
    var type: BaerCodeType
    var date: Int
}

struct BaerCoronaTest: Vaccination & CoronaTest & DocumentCellViewModel {
    var dateOfBirth: Date {
        return Date(timeIntervalSince1970: TimeInterval(dateOfBirthInt))
    }

    var vaccineType: String {
        return procedures.first?.type.category ?? "unknown"
    }

    var doseNumber: Int {
        return procedures.count
    }

    var dosesTotalNumber: Int {
        switch procedures[0].type {
        case .janssen:
            return 1
        default:
            return 2
        }
    }

    var version: Int
    var firstName: String
    var lastName: String
    var dateOfBirthInt: Int
    var diseaseType: Int
    var procedures: [BaerCoronaProcedure]
    var procedureOperator: String
    var result: Bool
    var originalCode: String

    var date: Date {
        let date = procedures[0].date
        return Date(timeIntervalSince1970: TimeInterval(date))
    }

    var testType: String {
        let type = procedures[0].type
        return type.category
    }

    var laboratory: String {
        return procedureOperator
    }

    var doctor: String {
        return " - "
    }

    var isNegative: Bool {
        return !result || isVaccine()
    }

    func isVaccine() -> Bool {
        return procedures[0].type.rawValue >= BaerCodeType.cormirnaty.rawValue
    }

    func daysSinceLastVaccine() -> Int {
        let lastVaccinationDate = Date(timeIntervalSince1970: TimeInterval(procedures[0].date))
        return Calendar.current.dateComponents([.day], from: lastVaccinationDate, to: Date()).day ?? Int.max
    }

    func vaccineState() -> BaerCodeVaccineState {
        if procedures.count == 2 ||
            procedures[0].type == .janssen { // J&J only needs one vaccination
            if daysSinceLastVaccine() >= 14 {
                return .complete
            }
            return .secondPending
        }
        return .firstVaccine
    }

    var identifier: Int {
        var checksum = Data()
        guard let nameData = (firstName + lastName).data(using: .utf8),
              let labData = procedureOperator.data(using: .utf8) else {
            return -1
        }
        checksum = nameData
        checksum.append(procedures[0].date.data)
        checksum.append(labData)
        return Int(checksum.crc32)
    }

    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool {
        let uppercaseAppFullname = (firstName + lastName).uppercased()
        let uppercaseTestFullname = (self.firstName + self.lastName).uppercased()
        return uppercaseAppFullname == uppercaseTestFullname
    }

    func isValid() -> Single<Bool> {
        Single.create { observer -> Disposable in
            var validity = 0.0
            switch procedures[0].type {
            case .fast:
                validity = 48.0
            case .pcr:
                validity = 72.0
            default:
                validity = Double.greatestFiniteMagnitude
            }
            let dateIsValid = TimeInterval(procedures[0].date) + TimeUnit.hour(amount: validity).timeInterval > Date().timeIntervalSince1970
            observer(.success(dateIsValid))

            return Disposables.create()
        }
    }

    func dequeueCell(_ tableView: UITableView, _ indexPath: IndexPath, delegate: DocumentCellDelegate) -> UITableViewCell {

        if self.isVaccine() {
            return dequeueVaccineCell(tableView, indexPath, vaccination: self, delegate: delegate)
        }

        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "CoronaTestTableViewCell", for: indexPath) as! CoronaTestTableViewCell
        cell.coronaTest = self
        cell.delegate = delegate

        return cell
    }

    private func dequeueVaccineCell(_ tableView: UITableView, _ indexPath: IndexPath, vaccination: Vaccination, delegate: DocumentCellDelegate) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "CoronaVaccineTableViewCell", for: indexPath) as! CoronaVaccineTableViewCell
        cell.vaccination = vaccination
        cell.delegate = delegate

        return cell
    }

}
