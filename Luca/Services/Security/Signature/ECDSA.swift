import Foundation
import Security

class ECDSA: Signature {
    private let privateKeySource: KeySource?
    private let publicKeySource: KeySource?
    private let algorithm: SecKeyAlgorithm

    init(privateKeySource: KeySource?, publicKeySource: KeySource?, algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256) {
        self.privateKeySource = privateKeySource
        self.publicKeySource = publicKeySource
        self.algorithm = algorithm
    }

    func sign(data: Data) throws -> Data {
        guard let keySource = privateKeySource else {
            throw CryptoError.noPrivateKeySource
        }
        guard let privateKey = keySource.retrieveKey() else {
            throw CryptoError.privateKeyNotRetrieved
        }
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey, algorithm, data as CFData, &error) as Data? else {
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
        let result = SecKeyVerifySignature(publicKey, algorithm, data as CFData, signature as CFData, &error)
        if let unwrappedError = error {
            throw unwrappedError.takeRetainedValue()
        }
        return result
    }

}
