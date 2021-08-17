import Foundation
import SwiftJWT
import RxSwift

class JWTParserWithOptionalDoctor: JWTCoronaTestParser<MeinCoronaTestClaims> {
    init(keyProvider: DocumentKeyProvider) {
        super.init(
            keyProvider: keyProvider) { (jwt, originalCode, provider) -> Document in
            return MeinCoronaTest(claims: jwt.claims, originalCode: originalCode, provider: provider)
        }
    }
}

struct MeinCoronaTestClaims: TestClaimsWithFingerprint {
    var f: String?

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
        case f = "f"
    }
}

struct MeinCoronaTest: JWTTest & CoronaTest {
    var version: Int
    var name: String
    var time: Int
    var category: Category
    var result: Result
    var lab: String
    var doc: String?
    var originalCode: String
    var provider: String

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

    init(claims: MeinCoronaTestClaims, originalCode: String, provider: String) {
        self.version = claims.version
        self.name = claims.name
        self.time = claims.time
        self.category = claims.category
        self.result = claims.result
        self.lab = claims.lab
        self.doc = claims.doc
        self.originalCode = originalCode
        self.provider = provider
    }
}

extension MeinCoronaTest {
    func belongsToUser(withFirstName firstName: String, lastName: String) -> Bool {
        let uppercaseFullname = (firstName + lastName).uppercased()
        let onlyAsciiName = uppercaseFullname.components(separatedBy: CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted).joined()
        let nameHash = onlyAsciiName.sha256()
        return nameHash == name
    }
}
