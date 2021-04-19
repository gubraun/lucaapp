import Foundation

protocol Preferences {

    func remove(key: String)

    func store(_ value: Double, key: String)
    func store(_ value: Int, key: String)
    func store(_ value: String, key: String)
    func store(_ value: Bool, key: String)
    func store(_ uuid: UUID, key: String)
    func store(_ data: Data, key: String)
    func store<T: Encodable>(_ data: T, key: String)

    func retrieve(key: String) -> Double?
    func retrieve(key: String) -> Int?
    func retrieve(key: String) -> String?
    func retrieve(key: String) -> Bool?
    func retrieve(key: String) -> Data?
    func retrieve(key: String) -> UUID?
    func retrieve<T: Decodable>(key: String, type: T.Type) -> T?

    /// Deprecated. It is used only for the bugfix LUCA 582.
    func retrieveArray<T: Decodable>(key: String, type: [T].Type) -> [T]

}
