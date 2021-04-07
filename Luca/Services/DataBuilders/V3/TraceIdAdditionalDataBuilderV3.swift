import Foundation

struct TraceIdAdditionalData: Codable {
    var table: Int
}

struct TraceIdAdditionalDataPayloadV3: Codable {
    var traceId: String
    var data: String
    var iv: String
    var mac: String
    var publicKey: String
}

class TraceIdAdditionalDataBuilderV3 {
    
    func decrypt<T>(destination: T.Type, venuePrivKey: KeySource, userPubKey: KeySource, data: Data, iv: Data) throws -> T where T: Decodable{
        let ecdh = ECDHSharedSecretKeySource(publicKeySource: userPubKey, privateKeySource: venuePrivKey)
        let ecdhKey: Data = try ecdh.retrieveKey()
        
        var tempData = ecdhKey
        tempData.append(0x01)
        let decKey = tempData.sha256().prefix(16)
        
        let crypto = self.crypto(encKey: decKey, iv: iv)
        let decrypted = try crypto.decrypt(data: data)
        
        let parsed = try JSONDecoder().decode(T.self, from: decrypted)
        return parsed
    }

    func build<T>(traceId: TraceId, scannerId: String, venuePubKey: KeySource, additionalData: T, scannerEPrivKey: SecKey? = nil) throws -> TraceIdAdditionalDataPayloadV3 where T: Encodable{

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

        guard let iv = KeyFactory.randomBytes(size: 16) else {
            throw NSError(domain: "Couldn't generate random data", code: 0, userInfo: nil)
        }

        let dhKey = try buildDHKey(scannerPrivateKey: privateEKey, venuePubKey: try venuePubKey.retrieveKey())
        let encKey = try buildENCKey(dhKey: dhKey)
        let payload = try JSONEncoder().encode(additionalData)
        let crypto = self.crypto(encKey: encKey, iv: iv)
        let encrypted = try crypto.encrypt(data: payload)
        let authKey = try buildAuthKey(dhKey: dhKey)
        let mac = try buildMac(encData: encrypted, authKey: authKey)

        let retVal = TraceIdAdditionalDataPayloadV3(
            traceId: traceId.traceIdString,
            data: encrypted.base64EncodedString(),
            iv: iv.base64EncodedString(),
            mac: mac.base64EncodedString(),
            publicKey: try publicEKey.toData().base64EncodedString())

        return retVal
    }

    func buildDHKey(scannerPrivateKey: SecKey, venuePubKey: SecKey) throws -> Data {
        let ecdh = ECDHSharedSecretKeySource(publicKeySource: ValueKeySource(key: venuePubKey), privateKeySource: ValueKeySource(key: scannerPrivateKey))
        return try ecdh.retrieveKey()
    }

    func buildENCKey(dhKey: Data) throws -> Data {
        var data = dhKey
        data.append(0x01)
        return data.sha256().prefix(16)
    }

    func buildAuthKey(dhKey: Data) throws -> Data {
        var data = dhKey
        data.append(0x02)
        return data.sha256()
    }

    func buildMac(encData: Data, authKey: Data) throws -> Data {
        let hmac = HMACSHA256(key: authKey)
        return try hmac.encrypt(data: encData)
    }

    func crypto(encKey: Data, iv: Data) -> Encryption & Decryption {
        let aes = AESCTRCrypto(keySource: ValueRawKeySource(key: encKey), iv: iv.bytes)
        return aes
    }
}
