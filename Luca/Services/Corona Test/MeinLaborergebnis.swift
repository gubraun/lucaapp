import Foundation
import RxSwift
import SwiftJWT

struct MeinLaborergebnisTestClaims: TestClaims {
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

struct MeinLaborergebnis: CoronaTest & DocumentCellViewModel {
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

    static func decodeTestCode(parse code: String) -> Single<CoronaTest> {
        Single.create { observer -> Disposable in
            do {
                var parameters = code
                if let index = code.firstIndex(of: "#") {
                    parameters = String(code.suffix(from: index))
                    parameters.removeFirst()
                }

                let publicKeyPath = Bundle.main.url(forResource: "meinlaborergebnis_jwtRS256", withExtension: "key.pub")!
                let publicKey: Data = try Data(contentsOf: publicKeyPath, options: .alwaysMapped)
                let verifier = JWTVerifier.rs256(publicKey: publicKey)
                let jwt = try JWT<MeinLaborergebnisTestClaims>(jwtString: parameters, verifier: verifier)
                observer(.success(MeinLaborergebnis(claims: jwt.claims, originalCode: parameters)))
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

    init(claims: MeinLaborergebnisTestClaims, originalCode: String) {
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

extension MeinLaborergebnis {
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

extension MeinLaborergebnis {

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
