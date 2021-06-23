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

struct DGCCoronaTest: CoronaTest & DocumentCellViewModel {
    var firstName: String
    var lastName: String
    var dateRaw: String
    var date: Date
    var testType: String
    var laboratory: String
    var doctor: String
    var isNegative: Bool
    var originalCode: String

    init(cert: DGCCert, test: DGCTestEntry, originalCode: String) {
        self.firstName = cert.firstName
        self.lastName = cert.lastName
        self.dateRaw = test.sampleTimeRaw
        self.date = test.sampleTime
        self.testType = DGCCoronaTestType(rawValue: test.type)!.category
        self.isNegative = test.resultNegative
        self.laboratory = test.testCenter
        self.doctor = test.issuer
        self.originalCode = originalCode
    }

    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool {
        let uppercaseAppFullname = (firstName + lastName).uppercased()
        let uppercaseTestFullname = (self.firstName + self.lastName).uppercased()
        return uppercaseAppFullname == uppercaseTestFullname
    }

    func isValid() -> Single<Bool> {
        Single.create { observer -> Disposable in
            let validity = DGCCoronaTestType(rawValue: self.testType) == .pcr ? 72 : 48
            let differenceHours = Calendar.current.dateComponents([.hour], from: self.date, to: Date()).hour ?? Int.max
            let dateIsValid = differenceHours < validity
            observer(.success(dateIsValid))

            return Disposables.create()
        }
    }
}
