import Foundation
import RealmSwift

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
    
    init(schemaVersion: UInt64, migrationBlock: MigrationBlock? = nil, customFilename: String? = nil) {
        
        dispatchQueue = DispatchQueue(label: "Realm.\(String(describing: Self.self))", qos: .background)
        
        let name = customFilename ?? String(describing: Self.self)
        
        let hashedName = name.data(using: .utf8)!.crc32().toHexString()
        
        // All various repos must be saved in separate files to be able to handle schema versions independently
        configuration = Realm.Configuration(
            fileURL: Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent().appendingPathComponent("\(hashedName).realm"),
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
    
    override func store(object: Model, completion: @escaping (Model)->Void, failure: @escaping ErrorCompletion) {
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
    
    override func store(objects: [Model], completion: @escaping ([Model])->Void, failure: @escaping ErrorCompletion) {
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
