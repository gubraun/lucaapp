import Foundation

struct UserDataPackageV3: Codable {
    var data: String
    var iv: String
    var publicKey: String?
    var signature: String
    var mac: String

    init(data: Data, iv: Data, signature: Data, mac: Data, publicKey: Data? = nil) {
        self.mac = mac.base64EncodedString()
        self.data = data.base64EncodedString()
        self.iv = iv.base64EncodedString()
        self.signature = signature.base64EncodedString()
        if let keyData = publicKey {
            self.publicKey = keyData.base64EncodedString()
        }
    }
}

class UserDataPackageBuilderV3 {
    private let bundle: UserKeysBundle

    init(userKeysBundle: UserKeysBundle) {
        bundle = userKeysBundle
    }

    var signature: Signature {
        ECDSA(privateKeySource: bundle.privateKey, publicKeySource: bundle.publicKey)
    }

    func crypto(iv: Data) throws -> Encryption & Decryption {
        let crypto = AESCTRCrypto(keySource: ValueRawKeySource(key: try buildEncryptionKey()), iv: iv.bytes)
        return crypto
    }

    func build(userData: UserRegistrationData, withPublicKey: Bool = true) throws -> UserDataPackageV3 {

        guard let publicKey = bundle.publicKey.retrieveKey() else {
            throw NSError(domain: "Couldn't retrieve public key", code: 0, userInfo: nil)
        }

        guard let iv = KeyFactory.randomBytes(size: 16) else {
            throw NSError(domain: "Couldn't generate random iv", code: 0, userInfo: nil)
        }

        // Build personal data
        let personalData = UserRegistrationDataIntermediate(userRegistrationData: userData)

        let personalDataJSON = try JSONEncoder().encode(personalData).unescaped()

        // Encode personal data
        let crypto = try self.crypto(iv: iv)
        let encData = try crypto.encrypt(data: personalDataJSON)

        let mac = try buildMac(encData: encData)

        // Build signature
        var dataToSign = Data(encData)
        dataToSign.append(mac)
        dataToSign.append(iv)

        let signature = try self.signature.sign(data: dataToSign)

        // Build the final UserDataPackage
        let publicKeyData: Data = try publicKey.toData()
        let userDataPackage = UserDataPackageV3(data: encData, iv: iv, signature: signature, mac: mac, publicKey: withPublicKey ? publicKeyData : nil)

        return userDataPackage
    }

    func buildEncryptionKey() throws -> Data {

        guard var userDataSecret = bundle.dataSecret.retrieveKey() else {
            throw NSError(domain: "Couldn't retrieve user data key", code: 0, userInfo: nil)
        }

        userDataSecret.append(0x01)

        let encKey = userDataSecret.sha256().prefix(16)
        return encKey
    }

    func buildMac(encData: Data) throws -> Data {
        let authKey = try buildAuthKey()
        let hmac = HMACSHA256(key: authKey)
        return try hmac.encrypt(data: encData)
    }

    func buildAuthKey() throws -> Data {

        guard var userDataSecret = bundle.dataSecret.retrieveKey() else {
            throw NSError(domain: "Couldn't retrieve user data key", code: 0, userInfo: nil)
        }

        userDataSecret.append(0x02)

        let encKey = userDataSecret.sha256()
        return encKey
    }
}

extension Data {
    func unescaped() throws -> Data {
        guard let string = String(data: self, encoding: .utf8) else {
            throw NSError(domain: "Coulnd't convert data to string", code: 0, userInfo: nil)
        }
        let unescaped = string.replacingOccurrences(of: "\\/", with: "/")
        return unescaped.data(using: .utf8)!
    }
}
