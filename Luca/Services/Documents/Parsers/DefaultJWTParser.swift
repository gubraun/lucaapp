import Foundation
import SwiftJWT

class DefaultJWTParser: JWTCoronaTestParser<JWTTestClaims> {
    init(keyProvider: DocumentKeyProvider) {
        super.init(
            keyProvider: keyProvider) { (jwt, originalCode, provider) -> Document in
            return JWTTestPayload(claims: jwt.claims, originalCode: originalCode, provider: provider)
        }
    }
}
