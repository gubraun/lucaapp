import Foundation
import Security

class KeyRepository<KeyType>: KeyRepositoryProtocol {

    func store(key: KeyType, removeIfExists: Bool = true) -> Bool {
        fatalError("Not implemented")
    }
    
    func restore() -> KeyType? {
        fatalError("Not implemented")
    }
    
    func purge() {
        fatalError("Not implemented")
    }
}
