import Foundation
import SwiftJWT

class TestNowAndEMTicketParser: JWTCoronaTestParser<JWTTestClaims> {
    init() {
        super.init(
            jwtParser: JWTParser(
                publicKeyFileURL: Bundle.main.url(forResource: "test_now_jwtRS256", withExtension: "key.pub")!,
                jwtVerifierCreator: JWTVerifier.rs256(publicKey:)
            )) { (jwt, originalCode) -> Document in

            // TODO: Remove after EM
            if jwt.claims.lab.hasPrefix("DFB") {
                return EMCoronaTest(claims: jwt.claims, originalCode: originalCode)
            }
            return JWTTestPayload(claims: jwt.claims, originalCode: originalCode)
        }
    }
}
