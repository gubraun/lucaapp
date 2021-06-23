import Foundation
import RealmSwift

struct DocumentPayload: DataRepoModel {
    var originalCode: String
    var identifier: Int?
}

class CoronaTestRealmModel: RealmSaveModel<DocumentPayload> {
    @objc dynamic var originalCode = ""

    override func create() -> DocumentPayload {
        return DocumentPayload(originalCode: "")
    }

    override func populate(from: DocumentPayload) {
        super.populate(from: from)
        originalCode = from.originalCode
    }

    override var model: DocumentPayload {
        var m = super.model
        m.originalCode = originalCode
        return m
    }

}

class DocumentRepo: RealmDataRepo<CoronaTestRealmModel, DocumentPayload> {

    override func createSaveModel() -> CoronaTestRealmModel {
        return CoronaTestRealmModel()
    }

    init(key: Data) {
        super.init(filenameSalt: "CoronaTestRepo", schemaVersion: 1, migrationBlock: { (migration, oldSchema) in
            if oldSchema < 1 {
                migration.enumerateObjects(ofType: CoronaTestRealmModel.className()) { oldObject, newObject in
                    if let oldObject = oldObject,
                       let newObject = newObject {
                        newObject["originalCode"] = oldObject["originalCode"]
                    }
                }
            }
        }, encryptionKey: key)
    }

}
