import Foundation
import RealmSwift

class AccessedTraceIdRealmModel: RealmSaveModel<AccessedTraceId> {

    @objc dynamic var healthDepartmentId = 0
    @objc dynamic var sightDate = Date()
    @objc dynamic var localNotificationDate: Date? = nil
    @objc dynamic var consumptionDate: Date? = nil
    let traceInfoIds = List<Int>()

    override func create() -> AccessedTraceId {
        return AccessedTraceId(healthDepartmentId: 0, traceInfoIds: [Int](), sightDate: Date())
    }
    
    override func populate(from: AccessedTraceId) {
        super.populate(from: from)
        healthDepartmentId = from.healthDepartmentId
        traceInfoIds.removeAll()
        traceInfoIds.append(objectsIn: from.traceInfoIds)
        sightDate = from.sightDate
        localNotificationDate = from.localNotificationDate
        consumptionDate = from.consumptionDate
    }
    
    override var model: AccessedTraceId {
        var m = super.model
        m.healthDepartmentId = healthDepartmentId
        m.traceInfoIds = [Int](traceInfoIds)
        m.sightDate = sightDate
        m.localNotificationDate = localNotificationDate
        m.consumptionDate = consumptionDate
        return m
    }

}

extension AccessedTraceId: DataRepoModel {
    
    var identifier: Int? {
        get {
            var checksum = Data()
            checksum.append(healthDepartmentId.data)
            traceInfoIds.forEach({ checksum.append($0.data) })
            return Int(checksum.crc32)
        }
        set { }
    }
    
}

class AccessedTraceIdRepo: RealmDataRepo<AccessedTraceIdRealmModel, AccessedTraceId> {
    
    override func createSaveModel() -> AccessedTraceIdRealmModel {
        return AccessedTraceIdRealmModel()
    }
    
    init() {
        super.init(schemaVersion: 1) { (migration, oldSchema) in
            if oldSchema < 1 {
                migration.renameProperty(onType: AccessedTraceIdRealmModel.className(), from: "date", to: "sightDate")
            }
        }
    }
    
}
