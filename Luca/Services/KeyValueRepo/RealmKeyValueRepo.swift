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

    init(key: Data?) {
        super.init(filenameSalt: "RealmKeyValueUnderlyingRepo", schemaVersion: 0, encryptionKey: key)
    }
}

enum RealmKeyValueRepoError: LocalizedTitledError {
    case encodingFailed
    case decodingFailed
    case storingFailed
    case objectNotFound
    case loadingFailed
    case removingFailed
    case unknown(error: Error)
}

extension RealmKeyValueRepoError {
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }

    var errorDescription: String? {
        return "\(self)"
    }
}

private struct ValueWrapper<T>: Codable where T: Codable {

    // This name is on purpose cryptic to reduce the probability of collisions with other custom data types
    var __temporaryValueWrapper: T
}

class RealmKeyValueRepo: KeyValueRepoProtocol {

    private let underlying: RealmKeyValueUnderlyingRepo

    init(key: Data?) {
        underlying = RealmKeyValueUnderlyingRepo(key: key)
    }

    func store<T>(_ key: String, value: T, completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) where T: Codable {
        guard let data = try? JSONEncoder().encode(ValueWrapper(__temporaryValueWrapper: value)) else {
            failure(RealmKeyValueRepoError.encodingFailed)
            return
        }
        underlying.store(
            object: KeyValueRepoEntry(key: key, data: data),
            completion: {_ in completion()},
            failure: { _ in failure(RealmKeyValueRepoError.storingFailed) }
        )
    }

    func load<T>(_ key: String, type: T.Type, completion: @escaping ((T) -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) where T: Codable {
        underlying.restore { (entries) in
            guard let entry = entries.first(where: { $0.key == key }) else {
                failure(RealmKeyValueRepoError.objectNotFound)
                return
            }
            let decoded: T

            // There may be some old values written without wrapper so try to do it first
            if let firstAttempt = try? JSONDecoder().decode(T.self, from: entry.data) {
                decoded = firstAttempt
            } else {

                // if that didn't work, try to decode it with the wrapper
                guard let secondAttempt = try? JSONDecoder().decode(ValueWrapper<T>.self, from: entry.data) else {
                    failure(RealmKeyValueRepoError.decodingFailed)
                    return
                }
                decoded = secondAttempt.__temporaryValueWrapper
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

    func removeFile(completion: @escaping() -> Void, failure: @escaping ((LocalizedTitledError) -> Void)) {
        underlying.removeFile(completion: completion) { (_) in
            failure(RealmKeyValueRepoError.removingFailed)
        }
    }

    func changeEncryptionSettings(oldKey: Data?, newKey: Data?, completion: @escaping () -> Void, failure: @escaping ((LocalizedTitledError) -> Void)) {
        underlying.changeEncryptionSettings(oldKey: oldKey, newKey: newKey, completion: completion) { (error) in
            if let localizedError = error as? LocalizedTitledError {
                failure(localizedError)
            } else {
                failure(RealmKeyValueRepoError.unknown(error: error))
            }
        }
    }
}

extension RealmKeyValueRepo: RealmDatabaseUtils {
    func removeFile(completion: @escaping () -> Void, failure: @escaping ((Error) -> Void)) {
        self.underlying.removeFile(completion: completion, failure: failure)
    }

    func changeEncryptionSettings(oldKey: Data?, newKey: Data?, completion: @escaping () -> Void, failure: @escaping ((Error) -> Void)) {
        self.underlying.changeEncryptionSettings(oldKey: oldKey, newKey: newKey, completion: completion, failure: failure)
    }
}
