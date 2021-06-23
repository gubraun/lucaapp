import Foundation
import RxSwift
import SwiftJWT

class Platform8Parser: JWTCoronaTestParser<JWTTestClaims> {
    init() {
        super.init(
            jwtParser: JWTParser(
                publicKeyFileURL: Bundle.main.url(forResource: "platform8_jwtRS256", withExtension: "key.pub")!,
                jwtVerifierCreator: JWTVerifier.rs256(publicKey:)
            )) { (jwt, originalCode) -> Document in
            JWTTestPayload(claims: jwt.claims, originalCode: originalCode)
        }
    }
}
