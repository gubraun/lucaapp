import Foundation

struct UserSecretEntry: Codable {
    var ts: Int
    var s: String
}

struct UserSecrets: Codable {
    var v: Int = 3
    var uid: String
    var uts: [UserSecretEntry]
    var uds: String
}

struct UserTransferDataV3: Codable {
    var data: String
    var iv: String
    var mac: String
    var publicKey: String
    var keyId: Int
}

class UserTransferBuilderV3 {
    let keysBundle: UserKeysBundle
    let dailyKeyRepo: DailyPubKeyHistoryRepository

    var dailyPubKeySource: KeySource!
    var newestId: DailyKeyIndex?

    init(userKeysBundle: UserKeysBundle, dailyKeyRepo: DailyPubKeyHistoryRepository) {
        keysBundle = userKeysBundle
        self.dailyKeyRepo = dailyKeyRepo
    }

    func lockDailyKey() throws {
        guard let newestId = dailyKeyRepo.newestId else {
            throw NSError(domain: "Couldn't lock the newest id: no id found", code: 0, userInfo: nil)
        }
        self.newestId = newestId
        dailyPubKeySource = try dailyKeyRepo.keySource(index: newestId)
    }

    func build(userId: UUID, definedIV: Data? = nil) throws -> UserTransferDataV3 {

        try lockDailyKey()

        guard let newestId = self.newestId else {
            throw NSError(domain: "No daily public key", code: 0, userInfo: nil)
        }

        var iv: Data! = definedIV

        if iv == nil {
            guard let generatedIV = KeyFactory.randomBytes(size: 16) else {
                throw NSError(domain: "Couldn't generate random data", code: 0, userInfo: nil)
            }
            iv = generatedIV
        }

        let dhKey = try buildDHKey()
        let encKey = buildEncKey(dhKey: dhKey)
        let authKey = buildAuthKey(dhKey: dhKey)
        let encData = try buildEncryptedUserSecretsData(iv: iv, userId: userId, encKey: encKey)
        let mac = try buildMac(encData: encData, authKey: authKey)
        let publicKey: Data = try keysBundle.publicKey.retrieveKey().toData()

        let retVal = UserTransferDataV3(
            data: encData.base64EncodedString(),
            iv: iv.base64EncodedString(),
            mac: mac.base64EncodedString(),
            publicKey: publicKey.base64EncodedString(),
            keyId: newestId.keyId)

        return retVal
    }

    func buildDHKey() throws -> Data {
        let ecdh = ECDHSharedSecretKeySource(publicKeySource: dailyPubKeySource, privateKeySource: keysBundle.privateKey)
        return try ecdh.retrieveKey()
    }

    func buildEncKey(dhKey: Data) -> Data {
        var data = dhKey
        data.append(0x01)
        return data.sha256().prefix(16)

    }

    func buildAuthKey(dhKey: Data) -> Data {
        var data = dhKey
        data.append(0x02)
        return data.sha256()
    }

    func buildEncryptedUserSecretsData(iv: Data, userId: UUID, encKey: Data) throws -> Data {
        let data = try buildUserSecretsData(userId: userId)

        let crypto = try self.crypto(iv: iv, encKey: encKey)
        return try crypto.encrypt(data: data)
    }

    func crypto(iv: Data, encKey: Data) throws -> Encryption & Decryption {
        let crypto = AESCTRCrypto(keySource: ValueRawKeySource(key: encKey), iv: iv.bytes)
        return crypto
    }

    func buildMac(encData: Data, authKey: Data) throws -> Data {
        let hmac = HMACSHA256(key: authKey)
        return try hmac.encrypt(data: encData)
    }

    func buildUserSecretsData(userId: UUID) throws -> Data {

        guard let thresholdDate = Calendar.current.date(byAdding: .day, value: -14, to: Date()) else {
            throw NSError(domain: "Couldn't generate threshold date for user secrets", code: 0, userInfo: nil)
        }

        let dates = keysBundle.traceSecrets.indices.filter { $0 > thresholdDate || Calendar.current.isDate(thresholdDate, inSameDayAs: $0) }

        let transferSecrets = dates
            .map { ($0.lucaTimestampInteger, try? keysBundle.traceSecrets.restore(index: $0)) }
            .filter { $0.1 != nil }
            .map { ($0.0, $0.1!) }

        let dataSecret: Data = try keysBundle.dataSecret.retrieveKey()

        let userSecrets = UserSecrets(
            uid: userId.uuidString.lowercased(),
            uts: transferSecrets.map { UserSecretEntry(ts: Int($0.0), s: $0.1.base64EncodedString()) },
            uds: dataSecret.base64EncodedString())

        return try JSONEncoderUnescaped().encode(userSecrets)
    }
}
