import Foundation
import SwiftJWT

class DefaultJWTParser: JWTCoronaTestParser<JWTTestClaims> {
    init(keyProvider: DocumentKeyProvider) {
        super.init(
            keyProvider: keyProvider) { (jwt, originalCode) -> Document in

            // TODO: Remove after EM
            if jwt.claims.lab.hasPrefix("DFB") {
                return EMCoronaTest(claims: jwt.claims, originalCode: originalCode)
            }
            return JWTTestPayload(claims: jwt.claims, originalCode: originalCode)
        }
    }
}
