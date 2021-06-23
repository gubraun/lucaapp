import Foundation
import SwiftJWT
import RxSwift

struct MeinCoronaTestClaims: TestClaims {
    var version: Int
    var name: String
    var time: Int
    var category: Category
    var result: Result
    var lab: String
    var doc: String?

    enum CodingKeys: String, CodingKey {
        case version = "v"
        case name = "n"
        case time = "t"
        case category = "c"
        case result = "r"
        case lab = "l"
        case doc = "d"
    }
}

struct MeinCoronaTest: CoronaTest & DocumentCellViewModel {
    var version: Int
    var name: String
    var time: Int
    var category: Category
    var result: Result
    var lab: String
    var doc: String?
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

    var doctor: String {
        return doc ?? " - "
    }

    var isNegative: Bool {
        return result.isNegative
    }

    init(claims: MeinCoronaTestClaims, originalCode: String) {
        self.version = claims.version
        self.name = claims.name
        self.time = claims.time
        self.category = claims.category
        self.result = claims.result
        self.lab = claims.lab
        self.doc = claims.doc
        self.originalCode = originalCode
    }
}

extension MeinCoronaTest {
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

class MeinCoronaParser: JWTCoronaTestParser<MeinCoronaTestClaims> {
    init() {
        super.init(
            jwtParser: JWTParser(
                publicKeyFileURL: Bundle.main.url(forResource: "test_meincoronatest_jwtRS256", withExtension: "key.pub")!,
                jwtVerifierCreator: JWTVerifier.rs256(publicKey:)
            )) { (jwt, originalCode) -> Document in
            MeinCoronaTest(claims: jwt.claims, originalCode: originalCode)
        }
    }
}
