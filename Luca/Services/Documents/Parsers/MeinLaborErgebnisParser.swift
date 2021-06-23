import Foundation
import SwiftJWT

typealias MeinLaborergebnisTestClaims = MeinCoronaTestClaims
typealias MeinLaborergebnisTest = MeinCoronaTest
class MeinLaborErgebnisParser: JWTCoronaTestParser<MeinLaborergebnisTestClaims> {
    init() {
        super.init(
            jwtParser: JWTParser(
                publicKeyFileURL: Bundle.main.url(forResource: "meinlaborergebnis_jwtRS256", withExtension: "key.pub")!,
                jwtVerifierCreator: JWTVerifier.rs256(publicKey:)
            )) { (jwt, originalCode) -> Document in
            MeinLaborergebnisTest(claims: jwt.claims, originalCode: originalCode)
        }
    }
}
