import Foundation
import Security

class SecKeyRepository: KeyRepository<SecKey> {
    private let tag: String

    init(tag: String) {
        self.tag = tag
    }

    override func store(key: SecKey, removeIfExists: Bool = true) -> Bool {
        let addQuery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecValueRef as String: key,
                                       kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock]

        if removeIfExists {
            purge()
        }

        let result = SecItemAdd(addQuery as CFDictionary, nil)
        return result == errSecSuccess
    }

    override func restore() -> SecKey? {
        let getQuery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecReturnRef as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        if status != errSecSuccess {
            return nil
        }

        // swiftlint:disable:next force_cast
        return (item as! SecKey)
    }

    override func purge() {
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrApplicationTag as String: tag]

        SecItemDelete(query as CFDictionary)
    }
}

extension KeyRepository: KeySource where KeyType == SecKey {
    func retrieveKey() -> SecKey? {
        return restore()
    }
}
