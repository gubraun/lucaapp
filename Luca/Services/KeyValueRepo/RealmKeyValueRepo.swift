import Foundation
import Realm

struct KeyValueRepoEntry: Codable {
    var key: String
    var data: Data
}

extension KeyValueRepoEntry: DataRepoModel {
    var identifier: Int? {
        get {
            Int((key.data(using: .utf8) ?? Data()).crc32)
        }
        set {}
    }
}

class KeyValueRepoEntryRealmModel: RealmSaveModel<KeyValueRepoEntry> {

    @objc dynamic var data = Data()
    @objc dynamic var key = ""

    override func create() -> KeyValueRepoEntry {
        return KeyValueRepoEntry(key: "", data: Data())
    }

    override func populate(from: KeyValueRepoEntry) {
        super.populate(from: from)
        data = from.data
        key = from.key
    }

    override var model: KeyValueRepoEntry {
        var m = super.model
        m.data = data
        m.key = key
        return m
    }
}

class RealmKeyValueUnderlyingRepo: RealmDataRepo<KeyValueRepoEntryRealmModel, KeyValueRepoEntry> {
    override func createSaveModel() -> KeyValueRepoEntryRealmModel {
        return KeyValueRepoEntryRealmModel()
    }

    init() {
        super.init(schemaVersion: 0)
    }
}

enum RealmKeyValueRepoError: LocalizedTitledError {
    case encodingFailed
    case decodingFailed
    case storingFailed
    case objectNotFound
    case loadingFailed
    case removingFailed
}

extension RealmKeyValueRepoError {
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }

    var errorDescription: String? {
        return "\(self)"
    }
}

class RealmKeyValueRepo: KeyValueRepoProtocol {

    private let underlying: RealmKeyValueUnderlyingRepo

    init() {
        underlying = RealmKeyValueUnderlyingRepo()
    }

    func store<T>(_ key: String, value: T, completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) where T: Encodable {
        guard let data = try? JSONEncoder().encode(value) else {
            failure(RealmKeyValueRepoError.encodingFailed)
            return
        }
        underlying.store(
            object: KeyValueRepoEntry(key: key, data: data),
            completion: {_ in completion()},
            failure: { _ in failure(RealmKeyValueRepoError.storingFailed) }
        )
    }

    func load<T>(_ key: String, type: T.Type, completion: @escaping ((T) -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) where T: Decodable {
        underlying.restore { (entries) in
            guard let entry = entries.first(where: { $0.key == key }) else {
                failure(RealmKeyValueRepoError.objectNotFound)
                return
            }
            guard let decoded = try? JSONDecoder().decode(T.self, from: entry.data) else {
                failure(RealmKeyValueRepoError.decodingFailed)
                return
            }
            completion(decoded)
        } failure: { (error) in
            if let expectedError = error as? LocalizedTitledError {
                failure(expectedError)
                return
            }
            failure(RealmKeyValueRepoError.loadingFailed)
        }
    }

    func remove(_ key: String, completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) {
        underlying.restore { (entries) in
            guard let entry = entries.first(where: { $0.key == key }) else {
                failure(RealmKeyValueRepoError.objectNotFound)
                return
            }
            self.underlying.remove(
                identifiers: [entry.identifier!],
                completion: completion,
                failure: { error in
                    if let expectedError = error as? LocalizedTitledError {
                        failure(expectedError)
                        return
                    }
                    failure(RealmKeyValueRepoError.loadingFailed)
                })
        } failure: { (error) in
            if let expectedError = error as? LocalizedTitledError {
                failure(expectedError)
                return
            }
            failure(RealmKeyValueRepoError.loadingFailed)
        }
    }

    func removeAll(completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) {
        underlying.removeAll(completion: completion, failure: { (error) in
            if let expectedError = error as? LocalizedTitledError {
                failure(expectedError)
                return
            }
            failure(RealmKeyValueRepoError.removingFailed)
        })
    }

}
