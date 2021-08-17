import Foundation
import RxSwift

enum DGCCoronaTestType: String, Codable {

    case fast = "LP217198-3"
    case pcr = "LP6464-4"
    case unknown

    public init(from decoder: Decoder) throws {
        self = try DGCCoronaTestType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }

    var category: String {
        switch self {
        case .fast: return L10n.Test.Result.fast
        case .pcr: return L10n.Test.Result.pcr
        default: return L10n.Test.Result.other
        }
    }
}

struct DGCCoronaTest: CoronaTest {
    var firstName: String
    var lastName: String
    var dateRaw: String
    var date: Date
    var testType: CoronaTestType
    var laboratory: String
    var isNegative: Bool
    var originalCode: String
    var hashSeed: String { originalCode }
    var provider = "DGC"

    var issuer: String
    var doctor: String { issuer }

    init(cert: DGCCert, test: DGCTestEntry, originalCode: String) {
        self.firstName = cert.firstName
        self.lastName = cert.lastName
        self.dateRaw = test.sampleTimeRaw
        self.date = test.sampleTime
        self.isNegative = test.resultNegative
        self.laboratory = test.testCenter
        self.issuer = test.issuer
        self.originalCode = originalCode

        switch DGCCoronaTestType(rawValue: test.type) ?? .unknown {
        case .fast:
            self.testType = .fast
        case .pcr:
            self.testType = .pcr
        case .unknown:
            self.testType = .other
        }
    }

    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool {
        let uppercaseAppFullname = (firstName + lastName).uppercased()
        let uppercaseTestFullname = (self.firstName + self.lastName).uppercased()
        return uppercaseAppFullname == uppercaseTestFullname
    }
}
