import Foundation
import RxSwift
import SwiftJWT

class JWTCoronaTestParser<ClaimsType>: DocumentParser where ClaimsType: ClaimsWithFingerprint & Codable {

    typealias JWTToCertificate = ((JWT<ClaimsType>, String, String) throws -> Document)

    private let jwtToCertificate: JWTToCertificate
    private let keyProvider: DocumentKeyProvider

    init(keyProvider: DocumentKeyProvider, jwtToCertificate: @escaping JWTToCertificate) {
        self.keyProvider = keyProvider
        self.jwtToCertificate = jwtToCertificate
    }

    private func createJWT(code: String) -> Single<JWT<ClaimsType>> {
        Single.from {
            let jwt: JWT<ClaimsType>
            do {
                jwt = try JWT<ClaimsType>(jwtString: code)
            } catch let error {
                if let jwtError = error as? JWTError, jwtError.localizedDescription.contains("JWT verifier failed") {
                    throw CoronaTestProcessingError.verificationFailed
                } else {
                    throw CoronaTestProcessingError.parsingFailed
                }
            }
            return jwt
        }
    }

    // Returns the name of the successfully verified test provider
    private func verify(jwt: JWT<ClaimsType>, code: String) -> Single<String> {
        if let fingerprint = jwt.claims.f {
            return keyProvider.get(with: fingerprint)
                .map { (key: "-----BEGIN PUBLIC KEY-----\n\($0.publicKey)\n-----END PUBLIC KEY-----", name: $0.name) }
                .map { (data: $0.key.data(using: .utf8) ?? Data(), name: $0.name) }
                .flatMap { (data, name) in
                    self.verifySingleKey(code: code, with: data).andThen(Single.just(name))
                }
        }
        return keyProvider.getAll()
            .flatMap { keys in
                let extractedKeys = keys
                    .map { (key: "-----BEGIN PUBLIC KEY-----\n\($0.publicKey)\n-----END PUBLIC KEY-----", name: $0.name) }
                    .map { (data: $0.key.data(using: .utf8), name: $0.name) }
                    .filter { $0.data != nil }
                    .map { ($0.data!, $0.name) }

                // Observables, which emit a 1 when verification is successful. Verification errors are omitted
                let observables = extractedKeys.map { (data, name) in
                    self.verifySingleKey(code: code, with: data)
                        .andThen(Observable.just(name))
                        .onErrorComplete()
                }

                // Sum all verifications and abort after first value (success)
                return Observable.merge(observables)
                    .take(1)
                    .toArray()
                    .map { array in
                        guard let name = array.first else {
                            throw CoronaTestProcessingError.verificationFailed
                        }
                        return name
                    }
            }
    }

    private func verifySingleKey(code: String, with publicKey: Data) -> Completable {
        Completable.from {
            let verifier = JWTVerifier.rs256(publicKey: publicKey)

            if !JWT<ClaimsType>.verify(code, using: verifier) {
                throw CoronaTestProcessingError.verificationFailed
            }
        }
    }

    func parse(code: String) -> Single<Document> {

        // Remove URL if present
        var parameters = code
        if let index = code.firstIndex(of: "#") {
            parameters = String(code.suffix(from: index))
            parameters.removeFirst()
        }

        return createJWT(code: parameters)
            .flatMap { jwt in
                self.verify(jwt: jwt, code: parameters)
                    .map { name in try self.jwtToCertificate(jwt, parameters, name) }
            }
    }
}
