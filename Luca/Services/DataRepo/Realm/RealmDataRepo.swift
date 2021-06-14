import Foundation
import RealmSwift
import RxSwift

class RealmSaveModel<Model>: Object where Model: DataRepoModel {

    let identifier = RealmOptional<Int>()

    override static func primaryKey() -> String? {
        return "identifier"
    }

    /// Populates this instance from the model
    func populate(from: Model) {
    }

    /// Creates empty result instance
    func create() -> Model {
        fatalError()
    }

    /// Populates the result model from this instance
    var model: Model {
        var m = create()
        m.identifier = identifier.value
        return m
    }
}

class RealmDataRepo<SaveModel, Model>: DataRepo<Model> where SaveModel: RealmSaveModel<Model> {
    private let dispatchQueue: DispatchQueue
    private let configuration: Realm.Configuration

    ///
    /// - Parameters:
    ///   - filenameSalt: The hash of this string will be the database filename.
    ///   - schemaVersion: Version of the schema. Migration callback will be triggered if the schema version won't match.
    ///   - migrationBlock: Callback that handles the migration.
    ///   - encryptionKey: If nil, data won't be encrypted. The key should be 64 bytes long.
    init(filenameSalt: String, schemaVersion: UInt64, migrationBlock: MigrationBlock? = nil, encryptionKey: Data? = nil) {

        dispatchQueue = DispatchQueue(label: "Realm.\(String(describing: Self.self))", qos: .background)

        let hashedName = filenameSalt.data(using: .utf8)!.crc32().toHexString()

        // All various repos must be saved in separate files to be able to handle schema versions independently
        configuration = Realm.Configuration(
            fileURL: Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent().appendingPathComponent("\(hashedName).realm"),
            encryptionKey: encryptionKey,
            schemaVersion: schemaVersion,
            migrationBlock: migrationBlock,
            objectTypes: [SaveModel.self])

        super.init()
    }

    func createSaveModel() -> SaveModel {
        fatalError()
    }

    private func createRealm() throws -> Realm {
        try Realm(configuration: configuration)
    }

    override func restore(completion: @escaping([Model]) -> Void, failure: @escaping ErrorCompletion) {

        dispatchQueue.async {
            autoreleasepool {
                do {
                    let realm = try self.createRealm()
                    let models = realm.objects(SaveModel.self).map { $0.model }
                    completion(Array(models))
                } catch let error {
                    failure(error)
                }
            }
        }
    }

    override func remove(identifiers: [Int], completion: @escaping() -> Void, failure: @escaping ErrorCompletion) {
        dispatchQueue.async {
            autoreleasepool {
                do {
                    let realm = try self.createRealm()
                    let models = realm.objects(SaveModel.self).filter { identifiers.contains($0.identifier.value ?? -1) }
                    try realm.write { realm.delete(models) }
                    completion()
                    NotificationCenter.default.post(name: NSNotification.Name(self.onDataChanged), object: self)
                } catch let error {
                    failure(error)
                }
            }
        }
    }

    override func removeAll(completion: @escaping() -> Void, failure: @escaping ErrorCompletion) {
        dispatchQueue.async {
            autoreleasepool {
                do {
                    let realm = try self.createRealm()
                    try realm.write { realm.deleteAll() }
                    completion()
                    NotificationCenter.default.post(name: NSNotification.Name(self.onDataChanged), object: self)
                } catch let error {
                    failure(error)
                }
            }
        }
    }

    override func store(object: Model, completion: @escaping (Model) -> Void, failure: @escaping ErrorCompletion) {
        dispatchQueue.async {
            autoreleasepool {
                do {
                    let realm = try self.createRealm()

                    completion(try self.store(object: object, realm: realm))
                    NotificationCenter.default.post(name: NSNotification.Name(self.onDataChanged), object: self)
                } catch let error {
                    failure(error)
                }
            }
        }
    }

    override func store(objects: [Model], completion: @escaping ([Model]) -> Void, failure: @escaping ErrorCompletion) {
        if objects.isEmpty {
            completion(objects)
            return
        }
        dispatchQueue.async {
            autoreleasepool {
                do {
                    let realm = try self.createRealm()

                    var retVals: [Model] = []
                    for object in objects {
                        retVals.append(try self.store(object: object, realm: realm))
                    }
                    completion(retVals)
                    NotificationCenter.default.post(name: NSNotification.Name(self.onDataChanged), object: self)
                } catch let error {
                    failure(error)
                }
            }
        }
    }

    private func store(object: Model, realm: Realm) throws -> Model {
        if let identifier = object.identifier,
           let foundObject = realm.object(ofType: SaveModel.self, forPrimaryKey: identifier) {
            try realm.write {
                foundObject.populate(from: object)
                realm.add(foundObject, update: .modified)
            }
            return foundObject.model
        } else {
            let model = self.createSaveModel()
            model.identifier.value = object.identifier ?? realm.objects(SaveModel.self).count
            try realm.write {
                model.populate(from: object)
                realm.add(model, update: .modified)
            }
            return model.model
        }
    }
}

extension RealmDataRepo: RealmDatabaseUtils {

    func removeFile(completion: @escaping() -> Void, failure: @escaping ErrorCompletion) {
        dispatchQueue.async {
            do {
                if FileManager.default.fileExists(atPath: self.configuration.fileURL!.path) {
                    try FileManager.default.removeItem(at: self.configuration.fileURL!)
                }
                completion()
            } catch let error {
                failure(error)
            }
        }
    }
    func changeEncryptionSettings(oldKey: Data?, newKey: Data?, completion: @escaping () -> Void, failure: @escaping ErrorCompletion) {
        if let oldKey = oldKey,
           oldKey.count != 64 {
            failure(NSError(domain: "Old key has invalid length", code: 0, userInfo: nil))
            return
        }
        if let newKey = newKey,
           newKey.count != 64 {
            failure(NSError(domain: "New key has invalid length", code: 0, userInfo: nil))
            return
        }

        // If the database has not been created yet then just return. New settings will be applied with the creation
        if !FileManager.default.fileExists(atPath: configuration.fileURL!.path) {
            completion()
            return
        }

        // Rename current database to a backup one
        let backupFilename = configuration.fileURL!.lastPathComponent.replacingOccurrences(of: ".realm", with: "_backup.realm")
        let backupURL = configuration.fileURL!.deletingLastPathComponent().appendingPathComponent(backupFilename)
        do {
            try FileManager.default.moveItem(at: configuration.fileURL!, to: backupURL)
        } catch let error {
            failure(error)
            return
        }

        // Create configuration with backup file URL and old key
        var oldConfiguration = configuration
        oldConfiguration.fileURL = backupURL
        oldConfiguration.encryptionKey = oldKey

        // Create configuration with the same URL as the initial DB and a new key
        var newConfiguration = configuration
        newConfiguration.encryptionKey = newKey
        dispatchQueue.async {
            do {
                let realm = try Realm(configuration: oldConfiguration)
                if FileManager.default.fileExists(atPath: self.configuration.fileURL!.path) {
                    try FileManager.default.removeItem(at: self.configuration.fileURL!)
                }
                try realm.writeCopy(toFile: self.configuration.fileURL!, encryptionKey: newKey)
                if FileManager.default.fileExists(atPath: backupURL.path) {
                    try FileManager.default.removeItem(at: backupURL)
                }
                completion()
            } catch let error {
                self.log("Failed to change encryption settings: \(error). Restoring backup file.", entryType: .error)
                do {
                    try FileManager.default.removeItem(at: newConfiguration.fileURL!)
                    try FileManager.default.moveItem(at: backupURL, to: self.configuration.fileURL!)
                } catch let e {
                    failure(e)
                    return
                }
                failure(error)
            }
        }
    }
}

extension RealmDataRepo: UnsafeAddress, LogUtil {

}
