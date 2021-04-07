import Foundation
import Security

public class RSAOAEPSHA256Crypto: Encryption, Decryption {
    private let publicKey: KeySource?
    private let privateKey: KeySource?
    
    init(publicKey: KeySource?, privateKey: KeySource? = nil) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    public func encrypt(data: Data) throws -> Data {
        guard let publicKeySource = publicKey else {
            log("Encrypt: No public key source", entryType: .error)
            throw CryptoError.noPublicKeySource
        }
        guard let publicKey = publicKeySource.retrieveKey() else {
            log("Encrypt: Couldn't retrieve public key!", entryType: .error)
            throw CryptoError.publicKeyNotRetrieved
        }
        var error: Unmanaged<CFError>?
        guard let encrypted = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionOAEPSHA256, data as CFData, &error) as Data? else {
            log("Couldn't encrypt data! \(error!.takeRetainedValue() as Error)/", entryType: .error)
            throw error!.takeRetainedValue()
        }
        return encrypted
    }
    
    public func decrypt(data: Data) throws -> Data {
        guard let privateKeySource = privateKey else {
            log("Decrypt: No private key source!", entryType: .error)
            throw CryptoError.noPrivateKeySource
        }
        guard let privateKey = privateKeySource.retrieveKey() else {
            log("Couldn't retrieve private key!", entryType: .error)
            throw CryptoError.privateKeyNotRetrieved
        }
        var error: Unmanaged<CFError>?
        guard let decrypted = SecKeyCreateDecryptedData(privateKey, .rsaEncryptionOAEPSHA256, data as CFData, &error) as Data? else {
            log("Couldn't decrypt data! \(error!.takeRetainedValue() as Error)/", entryType: .error)
            throw error!.takeRetainedValue()
        }
        return decrypted
    }
}

extension RSAOAEPSHA256Crypto: UnsafeAddress, LogUtil {}
