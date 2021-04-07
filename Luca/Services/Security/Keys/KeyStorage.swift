import Foundation
import Security

enum KeyStorageRetrievalType {
    case data
    case secKey
}

class KeyStorage {
    
    static private func addKeyQuery(tag: String? = nil, label: String? = nil) -> [String: Any] {
        var query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock]
        
        if let unwrappedLabel = label {
            query[kSecAttrApplicationLabel as String] = unwrappedLabel
        }
        if let unwrappedTag = tag {
            query[kSecAttrApplicationTag as String] = unwrappedTag
        }
        return query
    }
    
    static func store(key: Data, tag: String, label: String? = nil, removeIfExists: Bool = true) throws {
        
        var query = addKeyQuery(tag: tag, label: label)
        query[kSecValueData as String] = key
        
        var status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem  && removeIfExists {
            try purge(tag: tag, label: label)
            status = SecItemAdd(query as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil) }
    }
    
    static func store(key: SecKey, tag: String, label: String? = nil, removeIfExists: Bool = true) throws {
        
        var query = addKeyQuery(tag: tag, label: label)
        query[kSecValueRef as String] = key
        
        var status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem  && removeIfExists {
            try purge(tag: tag, label: label)
            status = SecItemAdd(query as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil) }
    }
    
    static func restore(dataType: KeyStorageRetrievalType, tag: String? = nil, label: String? = nil) -> [[String: Any]] {
        var query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecMatchLimit as String: kSecMatchLimitAll,
                                    kSecReturnAttributes as String: true]
        
        if dataType == .data {
            query[kSecReturnData as String] = true
        } else {
            query[kSecReturnRef as String] = true
        }
        
        if let unwrappedLabel = label {
            query[kSecAttrApplicationLabel as String] = unwrappedLabel
        }
        if let unwrappedTag = tag {
            query[kSecAttrApplicationTag as String] = unwrappedTag
        }
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status != errSecSuccess {
            return []
        }
        if let data = item as? [[String: Any]] {
            return data
        }
        return []
    }
    
    /// Removes all keys matching the given search
    ///
    /// If both parameters are nil, all keys in the app will be purged
    static func purge(tag: String? = nil, label: String? = nil) throws {
        
        var query: [String: Any] = [kSecClass as String: kSecClassKey]
        
        if let unwrappedLabel = label {
            query[kSecAttrApplicationLabel as String] = unwrappedLabel
        }
        if let unwrappedTag = tag {
            query[kSecAttrApplicationTag as String] = unwrappedTag
        }
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil) }
    }
}
