import Foundation
import SwiftJWT

class SodaParser: JWTCoronaTestParser<JWTTestClaims> {
    init() {
        super.init(
            jwtParser: JWTParser(
                publicKeyFileURL: Bundle.main.url(forResource: "test_soda_jwtRS256", withExtension: "key.pub")!,
                jwtVerifierCreator: JWTVerifier.rs256(publicKey:)
            )) { (jwt, originalCode) -> Document in
            JWTTestPayload(claims: jwt.claims, originalCode: originalCode)
        }
    }
}
