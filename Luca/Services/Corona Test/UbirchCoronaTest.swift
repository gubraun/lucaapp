import Foundation
import RxSwift
import SwiftJWT

struct UbirchCoronaTestClaims: TestClaims {
//    var version: Int
    var familyName: String
    var givenName: String
    var birthDate: String
    var passportId: String
    var laboratoryId: String
    var testDateTime: String
    var type: String   /// e.g. PCR
    var result: UbirchResult
    var secret: String

    enum CodingKeys: String, CodingKey {
        case familyName = "f"
        case givenName = "g"
        case birthDate = "b"
        case passportId = "p"
        case laboratoryId = "i"
        case testDateTime = "d"
        case type = "t"
        case result = "r"
        case secret = "s"
    }
}

struct UbirchCoronaTest: CoronaTest {
    var familyName: String
    var givenName: String
    var birthDate: String
    var passportId: String
    var laboratoryId: String
    var testDateTime: String
    var type: String
    var result: UbirchResult
    var secret: String
    var originalCode: String

    var date: Date {
        return Date.formatUbirchDateTimeString(dateString: testDateTime) ?? Date(timeIntervalSince1970: TimeInterval(0))
    }

    var testType: String {
        return type
    }

    var laboratory: String {
        return laboratoryId
    }

    var isNegative: Bool {
        return result.isNegative
    }

    var identifier: Int? {
        get {
            var checksum = Data()
            guard let nameData = (givenName + familyName).data(using: .utf8),
                  let timeData = testDateTime.data(using: .utf8),
                  let labData = laboratoryId.data(using: .utf8) else {
                return nil
            }
            checksum = nameData
            checksum.append(timeData)
            checksum.append(labData)
            return Int(checksum.crc32)
        }
        set { }
    }

    static func decodeTestCode(parse code: String) -> Single<CoronaTest> {
        Single.create { observer -> Disposable in
            do {
                var parameters = code
                if let index = code.firstIndex(of: "#") {
                    parameters = String(code.suffix(from: index))
                    parameters.removeFirst()
                }
                /// Parse ubirch format to json string
                let jsonString = "{\"" + parameters.replacingOccurrences(of: ";", with: "\",\"").replacingOccurrences(of: "=", with: "\":\"") + "\"}"
                let jsonData = jsonString.data(using: .utf8)!
                let claims = try JSONDecoder().decode(UbirchCoronaTestClaims.self, from: jsonData)

                observer(.success(UbirchCoronaTest(claims: claims, originalCode: parameters)))
            } catch {
                observer(.failure(CoronaTestProcessingError.parsingFailed))
            }

            return Disposables.create()
        }
    }

    init(claims: UbirchCoronaTestClaims, originalCode: String) {
        self.familyName = claims.familyName
        self.givenName = claims.givenName
        self.birthDate = claims.birthDate
        self.passportId = claims.passportId
        self.laboratoryId = claims.laboratoryId
        self.testDateTime = claims.testDateTime
        self.result = claims.result
        self.type = claims.type
        self.secret = claims.secret
        self.originalCode = originalCode
    }
}

extension UbirchCoronaTest {
    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool {
        let uppercaseAppFullname = (firstName + lastName).uppercased()
        let uppercaseTestFullname = (givenName + familyName).uppercased()
        return uppercaseAppFullname == uppercaseTestFullname
    }

    func isValid() -> Single<Bool> {
        Single.create { observer -> Disposable in
            let differenceHours = Calendar.current.dateComponents([.hour], from: self.date, to: Date()).hour ?? Int.max
            let dateIsValid = differenceHours < 48
            observer(.success(dateIsValid))

            return Disposables.create()
        }
    }
}

enum UbirchResult: String, Codable {

    case positive = "p"
    case negative = "n"
    case unknown = "x"

    var isNegative: Bool {
        switch self {
        case .negative: return true
        default: return false
        }
    }

}
