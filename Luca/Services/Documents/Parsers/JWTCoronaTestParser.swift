import Foundation
import RxSwift
import SwiftJWT

class JWTParser {
    private let pubKeyFile: URL
    private let jwtVerifierCreator: (Data) -> JWTVerifier

    init(publicKeyFileURL: URL, jwtVerifierCreator: @escaping (Data) -> JWTVerifier) {
        self.pubKeyFile = publicKeyFileURL
        self.jwtVerifierCreator = jwtVerifierCreator
    }

    func parse<T>(code: String) throws -> JWT<T> where T: Codable & Claims {
        let publicKey: Data = try Data(contentsOf: self.pubKeyFile, options: .alwaysMapped)
        let verifier = jwtVerifierCreator(publicKey)
        let jwt = try JWT<T>(jwtString: code, verifier: verifier)
        return jwt
    }
}

class JWTCoronaTestParser<ClaimsType>: DocumentParser where ClaimsType: Claims & Codable {

    typealias JWTToCertificate = ((JWT<ClaimsType>, String) throws -> Document)

    private let jwtParser: JWTParser
    private let jwtToCertificate: JWTToCertificate

    init(jwtParser: JWTParser, jwtToCertificate: @escaping JWTToCertificate) {
        self.jwtParser = jwtParser
        self.jwtToCertificate = jwtToCertificate
    }

    func parse(code: String) -> Single<Document> {
        Single.create { observer -> Disposable in

            // Remove URL if present
            var parameters = code
            if let index = code.firstIndex(of: "#") {
                parameters = String(code.suffix(from: index))
                parameters.removeFirst()
            }

            do {
                let jwt: JWT<ClaimsType> = try self.jwtParser.parse(code: parameters)
                let result = try self.jwtToCertificate(jwt, parameters)
                observer(.success(result))
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
