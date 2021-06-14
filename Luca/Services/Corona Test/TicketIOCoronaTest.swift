import Foundation
import RxSwift
import SwiftJWT

struct TicketIOCoronaTest: DefaultJWTTest {

    var version: Int
    var name: String
    var time: Int
    var category: Category
    var result: Result
    var lab: String
    var doctor: String
    var originalCode: String

    init(claims: DefaultJWTTestClaims, originalCode: String) {
        self.version = claims.version
        self.name = claims.name
        self.time = claims.time
        self.category = claims.category
        self.result = claims.result
        self.lab = claims.lab
        self.doctor = claims.doctor
        self.originalCode = originalCode
    }

    static func decodeTestCode(parse code: String) -> Single<CoronaTest> {
        Single.create { observer -> Disposable in
            do {
                var parameters = code
                if let index = code.firstIndex(of: "#") {
                    parameters = String(code.suffix(from: index))
                    parameters.removeFirst()
                }
                let publicKeyPath = Bundle.main.url(forResource: "test_io_jwtRS256", withExtension: "key.pub")!
                let publicKey: Data = try Data(contentsOf: publicKeyPath, options: .alwaysMapped)
                let verifier = JWTVerifier.rs256(publicKey: publicKey)
                let jwt = try JWT<DefaultJWTTestClaims>(jwtString: parameters, verifier: verifier)
                observer(.success(TicketIOCoronaTest(claims: jwt.claims, originalCode: parameters)))
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

}

extension TicketIOCoronaTest {

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
