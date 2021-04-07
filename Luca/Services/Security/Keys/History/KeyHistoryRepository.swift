import Foundation

class KeyHistoryRepository<IndexType, KeyType>: KeyHistoryRepositoryProtocol where IndexType: Hashable & Codable {
    
    private let header: String
    private(set) var indices: Set<IndexType> = []
    
    var factory: ((IndexType) throws -> KeyType)?
    
    var indexHeader: String {
        return header
    }
    
    init(header: String) {
        self.header = header
        self.load()
        print(arrayKey)
    }
    
    func store(key: KeyType, index: IndexType) throws {
        fatalError("Not implemented")
    }
    func restore(index: IndexType, enableFactoryIfAvailable: Bool = true) throws -> KeyType {
        fatalError("Not implemented")
    }
    func remove(index: IndexType) {
        fatalError("Not implemented")
    }
    func removeAll() {
        fatalError("Not implemented")
    }
    
    private var arrayKey: String {
        return "\(String(describing: self)).\(String(describing: IndexType.self)).\(indexHeader)"
    }
    
    /// Used to append new index. For internal use only.
    func addIndex(index: IndexType) {
        indices.insert(index)
        save()
    }
    
    /// Used to remove index. For internal use only.
    func removeIndex(index: IndexType) {
        indices.remove(index)
        save()
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: arrayKey),
           let set = try? JSONDecoder().decode(Set<IndexType>.self, from: data) {
            indices = set
        }
    }
    private func save() {
        
        let data = try! JSONEncoder().encode(indices)
        UserDefaults.standard.set(data, forKey: arrayKey)
    }
}
