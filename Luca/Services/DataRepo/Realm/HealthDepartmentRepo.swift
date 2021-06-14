import Foundation
import RealmSwift

class HealthDepartmentRealmModel: RealmSaveModel<HealthDepartment> {

    @objc dynamic var departmentId = ""
    @objc dynamic var name = ""
    @objc dynamic var publicHDEKP = ""
    @objc dynamic var publicHDSKP = ""

    override func create() -> HealthDepartment {
        return HealthDepartment(departmentId: "", name: "", publicHDEKP: "", publicHDSKP: "")
    }

    override func populate(from: HealthDepartment) {
        super.populate(from: from)
        departmentId = from.departmentId
        name = from.name
        publicHDEKP = from.publicHDEKP
        publicHDSKP = from.publicHDSKP
    }

    override var model: HealthDepartment {
        var m = super.model
        m.departmentId = departmentId
        m.name = name
        m.publicHDEKP = publicHDEKP
        m.publicHDSKP = publicHDSKP
        return m
    }
}

class HealthDepartmentRepo: RealmDataRepo<HealthDepartmentRealmModel, HealthDepartment> {
    override func createSaveModel() -> HealthDepartmentRealmModel {
        return HealthDepartmentRealmModel()
    }

    init(key: Data) {
        super.init(filenameSalt: "HealthDepartmentRepo", schemaVersion: 0, encryptionKey: key)
    }
}
