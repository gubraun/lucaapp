import Foundation

public class UserDataPreferences: Preferences {
    private let userDefaults: UserDefaults

    public init(suiteName: String) {
        userDefaults = UserDefaults(suiteName: suiteName)!
    }

    public init(suiteName: String, defaults: [String: Any]) {
        userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.register(defaults: defaults)
    }

    func remove(key: String) {
        userDefaults.removeObject(forKey: key)
    }

    public func store(_ value: Double, key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func store(_ value: Int, key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func store(_ value: String, key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func store(_ data: Data, key: String) {
        userDefaults.set(data, forKey: key)
    }

    public func store(_ bool: Bool, key: String) {
        userDefaults.set(bool, forKey: key)
    }

    public func store(_ uuid: UUID, key: String) {
        userDefaults.set(uuid.uuidString, forKey: key)
    }

    public func store<T: Encodable>(_ data: T, key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(data) {
            userDefaults.set(encoded, forKey: key)
        }
    }

    public func retrieve(key: String) -> Double? {
        if !userDefaults.dictionaryRepresentation().contains(where: { $0.key == key }) {
            return nil
        }
        return userDefaults.double(forKey: key)
    }

    public func retrieve(key: String) -> Int? {
        if !userDefaults.dictionaryRepresentation().contains(where: { $0.key == key }) {
            return nil
        }
        return userDefaults.integer(forKey: key)
    }

    public func retrieve(key: String) -> Bool? {
        if !userDefaults.dictionaryRepresentation().contains(where: { $0.key == key }) {
            return nil
        }
        return userDefaults.bool(forKey: key)
    }

    public func retrieve(key: String) -> String? {
        if !userDefaults.dictionaryRepresentation().contains(where: { $0.key == key }) {
            return nil
        }
        return userDefaults.string(forKey: key)
    }

    public func retrieve(key: String) -> UUID? {
        if !userDefaults.dictionaryRepresentation().contains(where: { $0.key == key }) {
            return nil
        }
        guard let uuid = userDefaults.string(forKey: key) else {
            return nil
        }
        return UUID(uuidString: uuid)
    }

    public func retrieve(key: String) -> Data? {
        if !userDefaults.dictionaryRepresentation().contains(where: { $0.key == key }) {
            return nil
        }
        return userDefaults.data(forKey: key)
    }

    public func retrieve<T: Decodable>(key: String, type: T.Type) -> T? {
        let decoder = JSONDecoder()
        if let data = userDefaults.data(forKey: key), let decodedData = try? decoder.decode(T.self, from: data) {
            return decodedData
        } else {
            return nil
        }
    }

    public func retrieveArray<T: Decodable>(key: String, type: [T].Type) -> [T] {
        let decoder = PropertyListDecoder()
        if let data = userDefaults.data(forKey: key), let decodedData = try? decoder.decode([T].self, from: data) {
            return decodedData
        } else {
            return []
        }
    }

}
