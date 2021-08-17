import Foundation
import RxSwift

enum BaerCodeVaccineState: Int {

    case firstVaccine = 1
    case secondPending = 2
    case complete = 3
}

struct BaerCodeVaccination: Vaccination {

    var version: Int
    var firstName: String
    var lastName: String
    var dateOfBirthInt: Int
    var diseaseType: Int
    var procedures: [BaerCoronaProcedure]
    var procedureOperator: String
    var originalCode: String
    var hashSeed: String { originalCode }

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

    init(payload: BaerCodePayload, originalCode: String) {
        self.version = payload.version
        self.firstName = payload.firstName
        self.lastName = payload.lastName
        self.dateOfBirthInt = payload.dateOfBirthInt
        self.diseaseType = payload.diseaseType
        self.procedures = payload.procedures
        self.procedureOperator = payload.procedureOperator
        self.originalCode = originalCode
    }

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

    func daysSinceLastVaccine() -> Int {
        let lastVaccinationDate = Date(timeIntervalSince1970: TimeInterval(procedures[0].date))
        return Calendar.current.dateComponents([.day], from: lastVaccinationDate, to: Date()).day ?? Int.max
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
        let uppercaseAppFullname = formatUser(withFirstName: firstName, lastName: lastName)
        let uppercaseTestFullname = formatUser(withFirstName: self.firstName, lastName: self.lastName)
        return uppercaseAppFullname == uppercaseTestFullname
    }

    private func formatUser(withFirstName firstName: String, lastName: String) -> String {
        return (firstName + lastName).uppercased()
            .removeOccurences(of: ["DR.", "PROF."])
            .removeNonUppercase()
            .removeWhitespaces()
    }
}
