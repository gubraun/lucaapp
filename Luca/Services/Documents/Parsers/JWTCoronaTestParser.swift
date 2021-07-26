import Foundation
import RxSwift
import SwiftJWT

class JWTCoronaTestParser<ClaimsType>: DocumentParser where ClaimsType: ClaimsWithFingerprint & Codable {

    typealias JWTToCertificate = ((JWT<ClaimsType>, String) throws -> Document)

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

    private func verify(jwt: JWT<ClaimsType>, code: String) -> Completable {
        if let fingerprint = jwt.claims.f {
            return keyProvider.get(with: fingerprint)
                .map { $0.publicKey.data(using: .utf8) ?? Data() }
                .flatMapCompletable { self.verifySingleKey(code: code, with: $0) }
        }
        return keyProvider.getAll()
            .flatMapCompletable { keys in
                let extractedKeys = keys
                    .map { $0.publicKey }
                    .map { "-----BEGIN PUBLIC KEY-----\n\($0)\n-----END PUBLIC KEY-----" }
                    .compactMap { $0.data(using: .utf8) }

                // Observables, which emit a 1 when verification is successful. Verification errors are omitted
                let observables = extractedKeys.map {
                    self.verifySingleKey(code: code, with: $0)
                        .andThen(Observable.just(1))
                        .onErrorComplete()
                }

                // Sum all verifications and abort after first value (success)
                return Observable.merge(observables)
                    .take(1)
                    .toArray()
                    .do(onSuccess: { array in

                        // If no values, there were no matching keys. Cannot be verified.
                        if array.isEmpty {
                            throw CoronaTestProcessingError.verificationFailed
                        }
                    })
                    .asCompletable()
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
                    .andThen(Single.from { try self.jwtToCertificate(jwt, parameters) })
            }
    }
}
