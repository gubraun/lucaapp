import Foundation
import RealmSwift

class CoronaTestRealmModel: RealmSaveModel<CoronaTestPayload> {
    @objc dynamic var originalCode = ""

    override func create() -> CoronaTestPayload {
        return CoronaTestPayload(originalCode: "")
    }

    override func populate(from: CoronaTestPayload) {
        super.populate(from: from)
        originalCode = from.originalCode
    }

    override var model: CoronaTestPayload {
        var m = super.model
        m.originalCode = originalCode
        return m
    }

}

class CoronaTestRepo: RealmDataRepo<CoronaTestRealmModel, CoronaTestPayload> {

    override func createSaveModel() -> CoronaTestRealmModel {
        return CoronaTestRealmModel()
    }

    init() {
        super.init(schemaVersion: 1) { (migration, oldSchema) in
            if oldSchema < 1 {
                migration.enumerateObjects(ofType: CoronaTestRealmModel.className()) { oldObject, newObject in
                    if let oldObject = oldObject,
                       let newObject = newObject {
                        newObject["originalCode"] = oldObject["originalCode"]
                    }
                }
            }
        }
    }

}
