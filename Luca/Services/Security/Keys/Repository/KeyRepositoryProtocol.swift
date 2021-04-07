import Foundation

protocol KeyRepositoryProtocol {
    
    associatedtype KeyType
    /// Stores the key.
    /// - returns: True if stored successfully, false if not
    /// - parameter key: Key to store
    /// - parameter removeIfExists: It will overwrite existed item if true. If false, it will save two items. Some implementation allow such situations.
    func store(key: KeyType, removeIfExists: Bool) -> Bool
    
    /// Restores the key
    /// - returns: Key, if present. Nil if something prevented the restoration
    func restore() -> KeyType?
    
    /// Removes the underlying item.
    func purge()
}
