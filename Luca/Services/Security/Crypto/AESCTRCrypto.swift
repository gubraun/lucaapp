import Foundation
import CryptoSwift

class AESCTRCrypto: Encryption, Decryption {
    private let keySource: RawKeySource
    
    private var iv: [UInt8] = []
    
    init(keySource: RawKeySource, iv: [UInt8]) {
        self.keySource = keySource
        self.iv = iv
    }
    
    /// Encrypts using given key and previously set IV
    func encrypt(data: Data) throws -> Data {
        guard let key = keySource.retrieveKey() else {
            log("Encrypt: Couldn't retrieve the key!")
            throw CryptoError.symmetricKeyNotRetrieved
        }
        
        do {
            let blockMode = CTR(iv: self.iv)
            let aes = try AES(key: key.bytes, blockMode: blockMode, padding: .noPadding)
            let bytes = try aes.encrypt(data.bytes)
            return Data(bytes)
        } catch let error {
            log("Couldn't encrypt data! \(error)")
            throw error
        }
    }
    
    /// Decrypts using given key and previously set IV
    func decrypt(data: Data) throws -> Data {
        guard let key = keySource.retrieveKey() else {
            log("Decrypt: Couldn't retrieve the key!")
            throw CryptoError.symmetricKeyNotRetrieved
        }
        
        do {
            let blockMode = CTR(iv: self.iv)
            let aes = try AES(key: key.bytes, blockMode: blockMode, padding: .noPadding)
            let bytes = try aes.decrypt(data.bytes)
            return Data(bytes)
        } catch let error {
            log("Couldn't decrypt data! \(error)")
            throw error
        }
    }
}

extension AESCTRCrypto: UnsafeAddress, LogUtil {}
