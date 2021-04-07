import Foundation
import Security

public enum KeyClass {
    case `public`
    case `private`
    case symmetric
}

extension KeyClass {
    var typeRawValue: CFString {
        switch self {
        case .private:
            return kSecAttrKeyClassPrivate
        case .public:
            return kSecAttrKeyClassPublic
        case .symmetric:
            return kSecAttrKeyClassSymmetric
        }
    }
}

public enum KeyType {
    case rsa
    case ec
    case ecsecPrimeRandom
}

extension KeyType {
    var typeRawValue: CFString {
        switch self {
        case .ec:
            return kSecAttrKeyTypeEC
        case .ecsecPrimeRandom:
            return kSecAttrKeyTypeECSECPrimeRandom
        case .rsa:
            return kSecAttrKeyTypeRSA
        }
    }
}

class KeyFactory {
    
    private static let logger = StandardLog(subsystem: "Crypto", category: "Key Factory", subDomains: [])
    
    static func create(from data: Data, type: KeyType, keyClass: KeyClass, sizeInBits: UInt) -> SecKey? {
        let attributes: [String: Any] = [kSecAttrKeyType as String: type.typeRawValue,
                                         kSecAttrKeyClass as String: keyClass.typeRawValue,
                                         kSecAttrKeySizeInBits as String: sizeInBits]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) as SecKey? else {
            logger.log("Couldn't create key from data! \(error!.takeRetainedValue() as Error)", entryType: .error)
            return nil
        }
        return key
    }
    
    static func create(from data: Data, type: KeyType, keyClass: KeyClass) -> SecKey? {
        let attributes: [String: Any] = [kSecAttrKeyType as String: type.typeRawValue,
                                         kSecAttrKeyClass as String: keyClass.typeRawValue]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) as SecKey? else {
            logger.log("Couldn't create key from data! \(error!.takeRetainedValue() as Error)", entryType: .error)
            return nil
        }
        return key
    }
    
    static func createPrivate(tag: String, type: KeyType, sizeInBits: UInt) -> SecKey? {
        let attributes: [String: Any] = [kSecAttrKeyType as String: type.typeRawValue,
                                         kSecAttrKeySizeInBits as String: sizeInBits,
                                         kSecPrivateKeyAttrs as String: [
                                            kSecAttrIsPermanent as String: true,
                                            kSecAttrApplicationTag as String: tag]]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            logger.log("Error creating a key: \(error!.takeRetainedValue() as Error)", entryType: .error)
            return nil
        }
        return key
    }
    
    static func derivePublic(from key: SecKey) -> SecKey? {
        return SecKeyCopyPublicKey(key)
    }
    
    static func createPrivateEC(x: Data, y: Data, d: Data, sizeInBits: UInt = 256) -> SecKey? {
        let data = NSMutableData(bytes: [0x04], length: 1)
        data.append(x)
        data.append(y)
        data.append(d)
        
        let attributes: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeEC,
                                         kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
                                         kSecAttrKeySizeInBits as String: sizeInBits,
                                         kSecAttrIsPermanent as String: false]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
            logger.log("Error creating private EC Key: \(error!.takeRetainedValue() as Error)", entryType: .error)
            return nil
        }
        return key
    }
    
    static func createPublicEC(x: Data, y: Data, sizeInBits: UInt = 256) -> SecKey? {
        let data = NSMutableData(bytes: [0x04], length: 1)
        data.append(x)
        data.append(y)
        
        let attributes: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeEC,
                                         kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                                         kSecAttrKeySizeInBits as String: sizeInBits,
                                         kSecAttrIsPermanent as String: false]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
            logger.log("Error creating public EC Key: \(error!.takeRetainedValue() as Error)", entryType: .error)
            return nil
        }
        return key
    }
    
    static func compressPublicEC(key: SecKey) throws -> Data {
        guard var keyData = key.toData() else {
            throw NSError(domain: "Error in compressing public ec key: data couldn't be retrieved", code: 0, userInfo: nil)
        }
        
        if keyData.bytes[0] != 0x04 {
            throw NSError(domain: "Error in compressing public ec key: key in an unknown format", code: 0, userInfo: nil)
        }
        
        if keyData.count != 65 {
            throw NSError(domain: "Error in compressing public ec key: key length invalid", code: 0, userInfo: nil)
        }
        
        let y = keyData.suffix(32)
        keyData.removeLast(32)
        keyData.removeFirst(1)
        
        let firstByte: UInt8 = (y.bytes[31] % 2) == 0 ? 0x02 : 0x03
        var data = Data()
        data.append(firstByte)
        data.append(keyData)
        
        return data
    }
    
    static func exchangeKeys(privateKey: SecKey, publicKey: SecKey, algorithm: SecKeyAlgorithm = .ecdhKeyExchangeStandard, requestedKeySize: UInt = 32) -> Data? {
        var error: Unmanaged<CFError>?
        let dict: [String: Any] = [SecKeyKeyExchangeParameter.requestedSize.rawValue as String: requestedKeySize]
        
        guard let result = SecKeyCopyKeyExchangeResult(privateKey,
                                                        algorithm,
                                                        publicKey,
                                                        dict as CFDictionary,
                                                        &error) as Data? else {
            logger.log("exchangeKeys: Failed: \(error!.takeRetainedValue() as Error)", entryType: .error)
            return nil
        }
        return result
    }
    
    static func randomBytes(size: Int) -> Data? {
        var bytes = [Int8](repeating: 0, count: size)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        if status == errSecSuccess {
            return Data(bytes: &bytes, count: size)
        }
        return nil
    }
}

extension SecKey {
    
    func toData() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        return data
    }
    
    func toData() -> Data? {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
            print(error!.takeRetainedValue() as Error)
            return nil
        }
        return data
    }
}
