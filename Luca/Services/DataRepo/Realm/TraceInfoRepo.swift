import Foundation
import RealmSwift

class TraceInfoRealmModel: RealmSaveModel<TraceInfo> {

    @objc dynamic var traceId = ""
    @objc dynamic var checkin = 0
    @objc dynamic var locationId = ""

    var checkout = RealmOptional<Int>()
    var createdAt = RealmOptional<Int>()

    override func create() -> TraceInfo {
        return TraceInfo(traceId: traceId, checkin: checkin, checkout: checkout.value, locationId: locationId, createdAt: createdAt.value)
    }

    override func populate(from: TraceInfo) {
        super.populate(from: from)
        traceId = from.traceId
        checkin = from.checkin
        locationId = from.locationId
        checkout.value = from.checkout
        createdAt.value = from.createdAt
    }

    override var model: TraceInfo {
        var m = super.model
        m.traceId = traceId
        m.checkin = checkin
        m.locationId = locationId
        m.checkout = checkout.value
        m.createdAt = createdAt.value
        return m
    }
}

class TraceInfoRepo: RealmDataRepo<TraceInfoRealmModel, TraceInfo> {
    override func createSaveModel() -> TraceInfoRealmModel {
        return TraceInfoRealmModel()
    }

    init(key: Data) {
        super.init(filenameSalt: "TraceInfoRepo", schemaVersion: 0, encryptionKey: key)
    }
}
