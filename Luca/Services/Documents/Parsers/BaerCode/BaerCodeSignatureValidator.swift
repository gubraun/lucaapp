import Foundation
import SwiftCBOR
import SwiftDGC

class BaerCodeSignatureValidator {

    public func verify(_ cbor: SwiftCBOR.CBOR, key: BaerCodeKey) throws -> Bool {
        guard
            case let SwiftCBOR.CBOR.tagged(tag, cborElement) = cbor,
            tag.rawValue == 98,
            case let SwiftCBOR.CBOR.array(array) = cborElement,
            case let SwiftCBOR.CBOR.array(signatureArray) = array[3],
            case let SwiftCBOR.CBOR.array(coseSignature) = signatureArray[0],
            case let SwiftCBOR.CBOR.byteString(signature) = coseSignature[2],
            let bytes = signedPayload(from: cbor)
        else {
            return false
        }

        // DER encoding
        let asnEncodedSignature = ASN1.encode(Data(signature), signature.count/2)

        // Get public key from key coordinates
        guard let publicKey = KeyFactory.createPublicEC(x: Data(key.xCoordECDSAKey), y: Data(key.yCoordECDSAKey), sizeInBits: 521)
        else {
            return false
        }

        let publicKeySource = ValueKeySource(key: publicKey)

        let ecdsa = ECDSA(privateKeySource: nil, publicKeySource: publicKeySource, algorithm: .ecdsaSignatureMessageX962SHA512)
        let isValid = try ecdsa.verify(data: bytes, signature: asnEncodedSignature)

        return isValid
    }

    private func signedPayload(from cbor: SwiftCBOR.CBOR) -> Data? {
        guard
            case let SwiftCBOR.CBOR.tagged(_, cborElement) = cbor,
            case let SwiftCBOR.CBOR.array(array) = cborElement,
            case let SwiftCBOR.CBOR.byteString(payload) = array[2],
            case let SwiftCBOR.CBOR.array(signatureArray) = array[3],
            case let SwiftCBOR.CBOR.array(coseSignature) = signatureArray[0]
        else {
            return nil
        }

        let signedPayload: [UInt8] = SwiftCBOR.CBOR.encode(
            [
                "Signature",
                SwiftCBOR.CBOR.byteString([]),
                coseSignature[0],
                SwiftCBOR.CBOR.byteString([]),
                SwiftCBOR.CBOR.byteString(payload)
            ]
        )
      return Data(signedPayload)
    }
}
