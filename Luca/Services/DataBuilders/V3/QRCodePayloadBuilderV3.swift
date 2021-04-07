import UIKit
import SwiftBase32

struct QRCodePayloadV3 {
    let qrCodeVersion: UInt8 = 3
    let deviceType: UInt8 = 0 //iOS
    let keyId: UInt8
    let timestamp: Data
    let traceId: Data
    let encData: Data
    let compressedEPubKey: Data
    let verificationTag: Data
}

extension QRCodePayloadV3 {
    /// Digested content ready to be displayed as QR Code
    var qrCodeData: Data {
        var d = rawData
        d.append(checksum)
        
        let encoded = d.base32EncodedData
        return encoded
    }
    
    var rawData: Data {
        var d = Data()
        d.append(qrCodeVersion) //Version: 3
        d.append(deviceType) //DeviceType: iOS
        d.append(keyId)
        d.append(timestamp)
        d.append(traceId)
        d.append(encData)
        d.append(compressedEPubKey)
        d.append(verificationTag)
        return d
    }
    
    private var checksum: Data {
        return rawData.sha256().prefix(4)
    }
    
    var parsedTraceId: TraceId? {
        let value = timestamp.withUnsafeBytes {
            $0.load(as: UInt32.self)
        }
        return TraceId(data: traceId, checkIn: Date(timeIntervalSince1970: Double(value)))
    }
}

class QRCodePayloadBuilderV3: NSObject {
    private let keysBundle: UserKeysBundle
    private let dailyKeyRepo: DailyPubKeyHistoryRepository
    private let ePubKeyRepo: EphemeralPublicKeyHistoryRepository
    private let ePrivKeyRepo: EphemeralPrivateKeyHistoryRepository
    
    init(keysBundle: UserKeysBundle,
         dailyKeyRepo: DailyPubKeyHistoryRepository,
         ePubKeyRepo: EphemeralPublicKeyHistoryRepository,
         ePrivKeyRepo: EphemeralPrivateKeyHistoryRepository) {
        self.keysBundle = keysBundle
        self.dailyKeyRepo = dailyKeyRepo
        self.ePubKeyRepo = ePubKeyRepo
        self.ePrivKeyRepo = ePrivKeyRepo
    }
    
    func build(for traceId: TraceIdCore, userID: UUID) throws -> QRCodePayloadV3 {
        let payload = QRCodePayloadV3(
            keyId: traceId.keyId,
            timestamp: traceId.date.lucaTimestamp,
            traceId: try self.traceId(core: traceId, userID: userID).data,
            encData: try buildEncryptedData(core: traceId, userID: userID),
            compressedEPubKey: try retrieveCompressedEPubKey(core: traceId),
            verificationTag: try buildVerificationTag(core: traceId, userID: userID))
        return payload
    }
    
    func traceId(core: TraceIdCore, userID: UUID) throws -> TraceId {
        print("Building trace ID for: \(core.date)")
        guard let key = try keysBundle.traceSecrets.keySource(index: core.date).retrieveKey() else {
            throw NSError(domain: "No trace secret found", code: 0, userInfo: nil)
        }
        var payload = Data()
        payload.append(Data(userID.bytes))
        payload.append(core.date.lucaTimestamp)
        let hmac = HMACSHA256(key: key)
        let fullTrace = try hmac.encrypt(data: payload)
        guard let traceId = TraceId(data: fullTrace.prefix(16), checkIn: core.date) else {
            throw NSError(domain: "Error initialising TraceId struct", code: 0, userInfo: nil)
        }
        return traceId
    }
    
    func buildDHKey(core: TraceIdCore) throws -> Data {
        let privateKey = try retrieveEPrivKey(checkIn: core.date)
        
        let dailyKey = try retrieveDailyPubKey(core: core)
        
        guard let dhKey = KeyFactory.exchangeKeys(privateKey: privateKey, publicKey: dailyKey, algorithm: .ecdhKeyExchangeStandard) else {
            throw NSError(domain: "Couldn't build ECDH key", code: 0, userInfo: nil)
        }
        
        return dhKey
    }
    
    func buildEncKey(core: TraceIdCore) throws -> Data {
        let dhKey = try buildDHKey(core: core)
        var payload = dhKey
        payload.append(0x01)
        payload = payload.sha256()
        payload = payload.prefix(16)
        return payload
    }
    
    func buildEncryptedData(core: TraceIdCore, userID: UUID) throws -> Data {
        var payload = Data()
        payload.append(Data(userID.bytes))
        payload.append(try retrieveUserDataSecret())
        
        let encKey = try buildEncKey(core: core)
        let iv = try retrieveIV(core: core)
        
        let crypto = AESCTRCrypto(keySource: ValueRawKeySource(key: encKey), iv: iv.bytes)
        let encrypted = try crypto.encrypt(data: payload)
        return encrypted
    }
    
    func buildVerificationTag(core: TraceIdCore, userID: UUID) throws -> Data {
        let encData = try buildEncryptedData(core: core, userID: userID)
        
        var payload = Data()
        payload.append(core.date.lucaTimestamp)
        payload.append(encData)
        
        var key = try retrieveUserDataSecret()
        key.append(0x02)
        
        let hmac = HMACSHA256(key: key.sha256())
        let fullTag = try hmac.encrypt(data: payload)
        return fullTag.prefix(8)
    }
    
    
    func retrieveEPubKey(checkIn: Date) throws -> SecKey {
        let keySource = try ePubKeyRepo.keySource(index: Int(checkIn.lucaTimestampInteger))
        guard let key = keySource.retrieveKey() else {
            throw NSError(domain: "Couldn't retrieve e public key from the keySource", code: 0, userInfo: nil)
        }
        return key
    }
    
    func retrieveEPrivKey(checkIn: Date) throws -> SecKey {
        let keySource = try ePrivKeyRepo.keySource(index: Int(checkIn.lucaTimestampInteger))
        guard let key = keySource.retrieveKey() else {
            throw NSError(domain: "Couldn't retrieve e private key from the keySource", code: 0, userInfo: nil)
        }
        return key
    }
    
    func retrieveCompressedEPubKey(core: TraceIdCore) throws -> Data {
        let key = try retrieveEPubKey(checkIn: core.date)
        let compressed = try KeyFactory.compressPublicEC(key: key)
        return compressed
    }
    
    func retrieveIV(core: TraceIdCore) throws -> Data {
        let epubKey = try retrieveCompressedEPubKey(core: core)
        let iv = epubKey.prefix(16)
        if iv.count != 16 {
            throw NSError(domain: "Couldn't generate IV from compressed pub key", code: 0, userInfo: nil)
        }
        return iv
    }
    
    func retrieveDailyPubKey(core: TraceIdCore) throws -> SecKey {
        guard let index = dailyKeyRepo.newest(withId: Int(core.keyId)) else {
            throw NSError(domain: "Couldn't retrieve the key index for given trace id core", code: 0, userInfo: nil)
        }
        let source = try dailyKeyRepo.keySource(index: index)
        guard let key = source.retrieveKey() else {
            throw NSError(domain: "Couldn't retrieve daily public key from the keySource", code: 0, userInfo: nil)
        }
        return key
    }
    
    func retrieveUserDataSecret() throws -> Data {
        guard let key = keysBundle.dataSecret.retrieveKey() else {
            throw NSError(domain: "Couldn't retrieve data secret", code: 0, userInfo: nil)
        }
        return key
    }
}
