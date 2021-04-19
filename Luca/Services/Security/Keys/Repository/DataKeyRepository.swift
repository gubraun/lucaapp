import Foundation
import Security

class DataKeyRepository: KeyRepository<Data> {
    private let tag: String

    init(tag: String) {
        self.tag = tag
    }

    override func store(key: Data, removeIfExists: Bool = true) -> Bool {
        let addQuery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecValueData as String: key,
                                       kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock]

        if removeIfExists {
            purge()
        }

        let result = SecItemAdd(addQuery as CFDictionary, nil)
        return result == errSecSuccess
    }

    override func restore() -> Data? {
        let getQuery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        if status != errSecSuccess {
            return nil
        }
        if let data = item as? Data {
            return data
        }
        return nil
    }

    override func purge() {
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrApplicationTag as String: tag]

        SecItemDelete(query as CFDictionary)
    }
}

extension KeyRepository: RawKeySource where KeyType == Data {
    func retrieveKey() -> Data? {
        return restore()
    }
}
