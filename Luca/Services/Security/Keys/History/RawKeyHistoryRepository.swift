import Foundation
import Security

fileprivate struct Wrapper<IndexType>: Codable where IndexType: Codable {
    var d: IndexType
}

class RawKeyHistoryRepository<IndexType>: KeyHistoryRepository<IndexType, Data> where IndexType: Hashable & Codable {
    
    private var tag: String {
        return "\(indexHeader).\(String(describing: self))"
    }
    
    override var indices: Set<IndexType> {
        let bufferedTag = tag
        
        let allKeys = KeyStorage.restore(dataType: .data, tag: bufferedTag)
            .filter { $0[kSecAttrApplicationTag as String] as? String == bufferedTag }
            
        let allStringIndices = allKeys
            .map { $0[kSecAttrApplicationLabel as String] as? Data }
            .filter { $0 != nil }
            .map { $0! }
            .map { String(data: $0, encoding: .utf8) }
            .filter { $0 != nil }
            .map { $0! }
            
        let allParsedIndices = allStringIndices
            .map { try? self.index(for: $0) }
            .filter { $0 != nil }
            .map { $0! }
        
        return Set(allParsedIndices)
        
    }
    
    override func store(key: Data, index: IndexType) throws {
        try KeyStorage.store(key: key, tag: tag, label: try string(for: index))
    }
    
    override func restore(index: IndexType, enableFactoryIfAvailable: Bool = true) throws -> Data {
        let array = try KeyStorage.restore(dataType: .data, tag: tag, label: string(for: index))
        if let first = array.first,
           let data = first[kSecValueData as String],
           let retVal = data as? Data {
            return retVal
        }
        if enableFactoryIfAvailable,
           let created = try factory?(index) {
            try store(key: created, index: index)
            return created
        }
        throw NSError(domain: "Some error on key retrieval", code: 0, userInfo: nil)
    }
    
    override func remove(index: IndexType) {
        try? KeyStorage.purge(tag: tag, label: string(for: index))
    }
    
    override func removeAll() {
        try? KeyStorage.purge(tag: tag)
    }
    
    private func string(for index: IndexType) throws -> String {
        return String(data: try JSONEncoder().encode(Wrapper(d: index)), encoding: .utf8)!
    }

    private func index(for string: String) throws -> IndexType {
        let data = string.data(using: .utf8)!
        return (try JSONDecoder().decode(Wrapper<IndexType>.self, from: data)).d
    }
}
