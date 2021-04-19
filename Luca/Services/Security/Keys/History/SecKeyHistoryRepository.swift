import Foundation
import Security

class SecKeyHistoryRepository<IndexType>: KeyHistoryRepository<IndexType, SecKey> where IndexType: Hashable & Codable {

    override func store(key: SecKey, index: IndexType) throws {
        let repo = try repository(for: index)
        if !repo.store(key: key) {
            throw NSError(domain: "Some error", code: 0, userInfo: nil)
        }
        addIndex(index: index)
    }

    override func restore(index: IndexType, enableFactoryIfAvailable: Bool = true) throws -> SecKey {
        let repo = try repository(for: index)
        if let key = repo.restore() {
            return key
        }
        if enableFactoryIfAvailable,
           let createdKey = try self.factory?(index) {
            try store(key: createdKey, index: index)
            return createdKey
        }
        throw NSError(domain: "Some error on key retrieval", code: 0, userInfo: nil)
    }

    override func remove(index: IndexType) {
        if let repo = try? repository(for: index) {
            repo.purge()
            removeIndex(index: index)
        }
    }

    override func removeAll() {
        for index in indices {
            remove(index: index)
        }
    }

    private func repository(for index: IndexType) throws -> SecKeyRepository {
        let object: [String: IndexType] = ["index": index]
        let serializedIndex = try JSONEncoder().encode(object)
        let hex = serializedIndex.toHexString()
        return SecKeyRepository(tag: "\(indexHeader).\(hex)")
    }
}
