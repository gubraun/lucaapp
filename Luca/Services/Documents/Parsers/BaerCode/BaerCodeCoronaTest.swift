import Foundation
import RxSwift

struct BaerCodeCoronaTest: CoronaTest {
    var version: Int
    var firstName: String
    var lastName: String
    var diseaseType: Int
    var procedures: [BaerCoronaProcedure]
    var procedureOperator: String
    var result: Bool
    var originalCode: String
    var hashSeed: String { originalCode }
    var provider = "BärCode"

    init(payload: BaerCodePayload, originalCode: String) {
        self.version = payload.version
        self.firstName = payload.firstName
        self.lastName = payload.lastName
        self.diseaseType = payload.diseaseType
        self.procedures = payload.procedures
        self.procedureOperator = payload.procedureOperator
        self.result = payload.result
        self.originalCode = originalCode
    }

    var date: Date {
        let date = procedures[0].date
        return Date(timeIntervalSince1970: TimeInterval(date))
    }

    var testType: CoronaTestType {
        switch procedures[0].type {
        case .fast:
            return .fast
        case .pcr:
            return .pcr
        default:
            return .other
        }
    }

    var laboratory: String {
        return procedureOperator
    }

    var doctor: String {
        return " - "
    }

    var isNegative: Bool {
        return !result
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
}
