import Foundation

protocol KeyValueRepoProtocol {
    func store<T>(_ key: String, value: T, completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) where T: Encodable
    func load<T>(_ key: String, completion: @escaping ((T) -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) where T: Decodable
    func remove(_ key: String, completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void))
    func removeAll(completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void))
}
