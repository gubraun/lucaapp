import Foundation

class ECDHSharedSecretKeySource: RawKeySource {
    
    private let privateKeySource: KeySource
    private let publicKeySource: KeySource
    
    init(publicKeySource: KeySource, privateKeySource: KeySource) {
        self.privateKeySource = privateKeySource
        self.publicKeySource = publicKeySource
    }
    
    func retrieveKey() -> Data? {
        guard let privateKey = privateKeySource.retrieveKey() else {
            log("Couldn't retrieve private key", entryType: .error)
            return nil
        }
        guard let publicKey = publicKeySource.retrieveKey() else {
            log("Couldn't retrieve public key", entryType: .error)
            return nil
        }
        
        guard let sharedSecret = KeyFactory.exchangeKeys(privateKey: privateKey,
                                                         publicKey: publicKey,
                                                         algorithm: .ecdhKeyExchangeStandard,
                                                         requestedKeySize: 32) else {
            log("Couldn't create shared secret from EC", entryType: .error)
            return nil
        }
        
        return sharedSecret
    }
}

extension ECDHSharedSecretKeySource: UnsafeAddress, LogUtil {}
