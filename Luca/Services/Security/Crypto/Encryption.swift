import Foundation

public enum CryptoError: Error {
    case privateKeyNotRetrieved
    case publicKeyNotRetrieved
    case symmetricKeyNotRetrieved

    case noPublicKeySource
    case noPrivateKeySource
    case noSharedKeySource
}

public protocol Encryption {
    func encrypt(data: Data) throws -> Data
}
