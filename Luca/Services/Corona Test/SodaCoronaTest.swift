import Foundation
import RxSwift
import SwiftJWT

struct SodaCoronaTestClaims: TestClaims {
    var version: Int
    var name: String
    var time: Int
    var category: SodaCategory
    var result: SodaResult
    var lab: String
    var doctor: String

    enum CodingKeys: String, CodingKey {
        case version = "v"
        case name = "n"
        case time = "t"
        case category = "c"
        case result = "r"
        case lab = "l"
        case doctor = "d"
    }
}

struct SodaCoronaTest: CoronaTest {
    var version: Int
    var name: String
    var time: Int
    var category: SodaCategory
    var result: SodaResult
    var lab: String
    var doctor: String
    var originalCode: String

    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(time))
    }

    var testType: String {
        return category.category
    }

    var laboratory: String {
        return lab
    }

    var isNegative: Bool {
        return result.isNegative
    }

    static func decodeTestCode(parse code: String) -> Single<CoronaTest> {
        Single.create { observer -> Disposable in
            do {
                var parameters = code
                if let index = code.firstIndex(of: "#") {
                    parameters = String(code.suffix(from: index))
                    parameters.removeFirst()
                }

                let publicKeyPath = Bundle.main.url(forResource: "test_soda_jwtRS256", withExtension: "key.pub")!
                let publicKey: Data = try Data(contentsOf: publicKeyPath, options: .alwaysMapped)
                let verifier = JWTVerifier.rs256(publicKey: publicKey)
                let jwt = try JWT<SodaCoronaTestClaims>(jwtString: parameters, verifier: verifier)
                observer(.success(SodaCoronaTest(claims: jwt.claims, originalCode: parameters)))
            } catch let error {
                if let jwtError = error as? JWTError, jwtError.localizedDescription.contains("JWT verifier failed") {
                    observer(.failure(CoronaTestProcessingError.verificationFailed))
                } else {
                    observer(.failure(CoronaTestProcessingError.parsingFailed))
                }
            }

            return Disposables.create()
        }
    }

    init(claims: SodaCoronaTestClaims, originalCode: String) {
        self.version = claims.version
        self.name = claims.name
        self.time = claims.time
        self.category = claims.category
        self.result = claims.result
        self.lab = claims.lab
        self.doctor = claims.doctor
        self.originalCode = originalCode
    }
}

extension SodaCoronaTest {
    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool {
        let uppercaseFullname = (firstName + lastName).uppercased()
        let onlyAsciiName = uppercaseFullname.components(separatedBy: CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted).joined()
        let nameHash = onlyAsciiName.sha256()
        return nameHash == name
    }

    func isValid() -> Single<Bool> {
        Single.create { observer -> Disposable in
            let dateIsValid = TimeInterval(time) + TimeUnit.hour(amount: 48).timeInterval > Date().timeIntervalSince1970
            observer(.success(dateIsValid))

            return Disposables.create()
        }
    }
}

extension SodaCoronaTest: DataRepoModel {

    var identifier: Int? {
        get {
            var checksum = Data()
            checksum = name.data(using: .utf8)!
            checksum.append(time.data)
            checksum.append(lab.data(using: .utf8)!)
            return Int(checksum.crc32)
        }
        set { }
    }

}

enum SodaResult: String, Codable {

    case positive = "p"
    case negative = "n"

    var isNegative: Bool {
        switch self {
        case .negative: return true
        default: return false
        }
    }

}

enum SodaCategory: String, Codable {

    case fast = "f"
    case pcr = "p"
    case other = "o"

    var category: String {
        switch self {
        case .fast: return L10n.Test.Result.fast
        case .pcr: return L10n.Test.Result.pcr
        default: return L10n.Test.Result.other
        }
    }

}
