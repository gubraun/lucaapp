import SwiftCBOR

class BaerCodeSignatureValidator {

    public func verify(_ cbor: CBOR, key: BaerCodeKey) throws -> Bool {
        guard
            case let CBOR.tagged(tag, cborElement) = cbor,
            tag.rawValue == 98,
            case let CBOR.array(array) = cborElement,
            case let CBOR.array(signatureArray) = array[3],
            case let CBOR.array(coseSignature) = signatureArray[0],
            case let CBOR.byteString(signature) = coseSignature[2],
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

    private func signedPayload(from cbor: CBOR) -> Data? {
        guard
            case let CBOR.tagged(_, cborElement) = cbor,
            case let CBOR.array(array) = cborElement,
            case let CBOR.byteString(payload) = array[2],
            case let CBOR.array(signatureArray) = array[3],
            case let CBOR.array(coseSignature) = signatureArray[0]
        else {
            return nil
        }

        let signedPayload: [UInt8] = CBOR.encode(
            [
                "Signature",
                CBOR.byteString([]),
                coseSignature[0],
                CBOR.byteString([]),
                CBOR.byteString(payload)
            ]
        )
      return Data(signedPayload)
    }
}
