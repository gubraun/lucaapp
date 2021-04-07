import Foundation

protocol KeyHistoryRepositoryProtocol {
    associatedtype KeyType
    associatedtype IndexType
    
    /// Used when accessed index does not exist
    var factory: ((IndexType) throws -> KeyType)? { get set }
    
    /// Used to avoid conflicts for same keys across various history repositories
    var indexHeader: String { get }
    
    func store(key: KeyType, index: IndexType) throws
    func restore(index: IndexType, enableFactoryIfAvailable: Bool) throws -> KeyType
    func remove(index: IndexType)
    func removeAll()
}

extension KeyHistoryRepositoryProtocol where KeyType == SecKey {
    func keySource(index: IndexType, enableFactoryIfAvailable: Bool = true) throws -> KeySource {
        let key: SecKey = try restore(index: index, enableFactoryIfAvailable: enableFactoryIfAvailable)
        return ValueKeySource(key: key)
    }
}

extension KeyHistoryRepositoryProtocol where KeyType == Data {
    func keySource(index: IndexType, enableFactoryIfAvailable: Bool = true) throws -> RawKeySource {
        let key: Data = try restore(index: index, enableFactoryIfAvailable: enableFactoryIfAvailable)
        return ValueRawKeySource(key: key)
    }
}
