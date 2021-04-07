import Foundation
import RealmSwift

class TraceIdCoreRealmModel: RealmSaveModel<TraceIdCore> {
    
    @objc dynamic var date = Date()
    @objc dynamic var keyId = 0

    override func create() -> TraceIdCore {
        return TraceIdCore(date: date, keyId: UInt8(keyId))
    }

    override func populate(from: TraceIdCore) {
        super.populate(from: from)
        date = from.date
        keyId = Int(from.keyId)
    }

    override var model: TraceIdCore {
        var m = super.model
        m.date = date
        m.keyId = UInt8(keyId)
        return m
    }
}

class TraceIdCoreRepo: RealmDataRepo<TraceIdCoreRealmModel, TraceIdCore> {
    override func createSaveModel() -> TraceIdCoreRealmModel {
        return TraceIdCoreRealmModel()
    }
    
    init() {
        super.init(schemaVersion: 0)
    }
}
