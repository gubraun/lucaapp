import Foundation
import RealmSwift

class PersonRealmModel: RealmSaveModel<Person> {

    @objc dynamic var firstName: String = ""
    @objc dynamic var lastName: String = ""

    let traceInfos = List<Int>()

    override func create() -> Person {
        return Person(firstName: "", lastName: "")
    }

    override func populate(from: Person) {
        super.populate(from: from)

        firstName = from.firstName
        lastName = from.lastName
        traceInfos.removeAll()
        traceInfos.append(objectsIn: from.traceInfoIDs)
    }

    override var model: Person {
        var m = super.model

        m.firstName = firstName
        m.lastName = lastName
        m.traceInfoIDs = Array(traceInfos)
        return m
    }
}

class PersonRepo: RealmDataRepo<PersonRealmModel, Person> {
    override func createSaveModel() -> PersonRealmModel {
        return PersonRealmModel()
    }

    init(key: Data) {
        super.init(filenameSalt: "PersonRepo", schemaVersion: 0, encryptionKey: key)
    }
}
