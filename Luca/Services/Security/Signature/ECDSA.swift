import Foundation
import Security

class ECDSA: Signature {
    private let privateKeySource: KeySource?
    private let publicKeySource: KeySource?

    init(privateKeySource: KeySource?, publicKeySource: KeySource?) {
        self.privateKeySource = privateKeySource
        self.publicKeySource = publicKeySource
    }

    func sign(data: Data) throws -> Data {
        guard let keySource = privateKeySource else {
            throw CryptoError.noPrivateKeySource
        }
        guard let privateKey = keySource.retrieveKey() else {
            throw CryptoError.privateKeyNotRetrieved
        }
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey, .ecdsaSignatureMessageX962SHA256, data as CFData, &error) as Data? else {
            throw error!.takeRetainedValue()
        }
        return signature
    }

    func verify(data: Data, signature: Data) throws -> Bool {
        guard let keySource = publicKeySource else {
            throw CryptoError.noPublicKeySource
        }
        guard let publicKey = keySource.retrieveKey() else {
            throw CryptoError.publicKeyNotRetrieved
        }

        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(publicKey, .ecdsaSignatureMessageX962SHA256, data as CFData, signature as CFData, &error)
        if let unwrappedError = error {
            throw unwrappedError.takeRetainedValue()
        }
        return result
    }

}
