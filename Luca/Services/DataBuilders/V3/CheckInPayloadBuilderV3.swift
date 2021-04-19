import UIKit

struct CheckInPayloadV3: Codable {
    var traceId: String
    var scannerId: String
    var timestamp: Int
    var data: String
    var iv: String
    var mac: String
    var publicKey: String
    var deviceType: Int = 0
}

class CheckInPayloadBuilderV3 {
    func build(qrCode: QRCodePayloadV3,
               venuePublicKey: KeySource,
               scannerId: String,
               scannerEPrivKey: SecKey? = nil) throws -> CheckInPayloadV3 {

        var privateEKey: SecKey! = scannerEPrivKey
        if privateEKey == nil {
            guard let key = KeyFactory.createPrivate(tag: "", type: .ecsecPrimeRandom, sizeInBits: 256) else {
                throw NSError(domain: "Private key couldn't be created", code: 0, userInfo: nil)
            }
            privateEKey = key
        }
        guard let publicEKey = KeyFactory.derivePublic(from: privateEKey) else {
            throw NSError(domain: "Public key couldn't be derived", code: 0, userInfo: nil)
        }

        guard let traceId = qrCode.parsedTraceId else {
            throw NSError(domain: "Couldn't parse out trace id from the qr code", code: 0, userInfo: nil)
        }

        let rawPayload = try buildRawPayload(qrCode: qrCode)

        guard let iv = KeyFactory.randomBytes(size: 16) else {
            throw NSError(domain: "Couldn't generate random IV", code: 0, userInfo: nil)
        }

        let dhKey = try buildDHKey(venuePublicKey: venuePublicKey, scannerEPrivKey: ValueKeySource(key: privateEKey))

        let encData = try buildEncryptedPayload(rawPayload: rawPayload, iv: iv, dhKey: dhKey)

        let timestamp = qrCode.timestamp.withUnsafeBytes {
            $0.load(as: UInt32.self)
        }

        let mac = try buildMac(authKey: try buildAuthKey(dhKey: dhKey), encData: encData)

        let checkInPayload = CheckInPayloadV3(
            traceId: traceId.traceIdString,
            scannerId: scannerId,
            timestamp: Int(timestamp),
            data: encData.base64EncodedString(),
            iv: iv.base64EncodedString(),
            mac: mac.base64EncodedString(),
            publicKey: (try publicEKey.toData()).base64EncodedString())

        return checkInPayload
    }

    func buildEncryptedPayload(rawPayload: Data,
                               iv: Data,
                               dhKey: Data) throws -> Data {

        let encKey = try buildEncKey(dhKey: dhKey)

        let crypto = self.crypto(encKey: encKey, iv: iv)

        let encData = try crypto.encrypt(data: rawPayload)

        return encData
    }

    func buildRawPayload(qrCode: QRCodePayloadV3) throws -> Data {
        var payload = Data()
        payload.append(0x03)
        payload.append(qrCode.keyId)
        payload.append(qrCode.compressedEPubKey)
        payload.append(qrCode.verificationTag)
        payload.append(qrCode.encData)
        return payload
    }

    func buildMac(authKey: Data, encData: Data) throws -> Data {
        let hmac = HMACSHA256(key: authKey)
        return try hmac.encrypt(data: encData)
    }

    func buildDHKey(venuePublicKey: KeySource, scannerEPrivKey: KeySource) throws -> Data {
        let ecdh = ECDHSharedSecretKeySource(publicKeySource: venuePublicKey, privateKeySource: scannerEPrivKey)
        return try ecdh.retrieveKey()
    }

    func buildEncKey(dhKey: Data) throws -> Data {
        var key = dhKey
        key.append(0x01)
        return key.sha256().prefix(16)
    }

    func buildAuthKey(dhKey: Data) throws -> Data {
        var key = dhKey
        key.append(0x02)
        return key.sha256()
    }

    func crypto(encKey: Data, iv: Data) -> Encryption & Decryption {
        let aes = AESCTRCrypto(keySource: ValueRawKeySource(key: encKey), iv: iv.bytes)
        return aes
    }
}
