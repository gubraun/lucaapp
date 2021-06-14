import Foundation
import RealmSwift

class LocationRealmModel: RealmSaveModel<Location> {

    @objc dynamic var locationId: String = ""
    @objc dynamic var publicKey: String = ""
    @objc dynamic var radius: Double = 0.0
    @objc dynamic var name: String?
    @objc dynamic var locationName: String?
    @objc dynamic var groupName: String?
    @objc dynamic var firstName: String?
    @objc dynamic var lastName: String?
    @objc dynamic var phone: String?
    @objc dynamic var streetName: String?
    @objc dynamic var streetNr: String?
    @objc dynamic var zipCode: String?
    @objc dynamic var city: String?
    @objc dynamic var state: String?

    var lat = RealmOptional<Double>()
    var lng = RealmOptional<Double>()
    var startsAt = RealmOptional<Int>()
    var endsAt = RealmOptional<Int>()
    var isPrivate = RealmOptional<Bool>()

    override func create() -> Location {
        return Location(locationId: "", publicKey: "", radius: 0)
    }

    override func populate(from: Location) {
        super.populate(from: from)

        locationId = from.locationId
        publicKey = from.publicKey
        radius = from.radius
        name = from.name
        locationName = from.locationName
        groupName = from.groupName
        firstName = from.firstName
        lastName = from.lastName
        phone = from.phone
        streetName = from.streetName
        streetNr = from.streetNr
        zipCode = from.zipCode
        city = from.city
        state = from.state

        lat.value = from.lat
        lng.value = from.lng
        startsAt.value = from.startsAt
        endsAt.value = from.endsAt
        isPrivate.value = from.isPrivate
    }

    override var model: Location {
        var m = super.model

        m.locationId = locationId
        m.publicKey = publicKey
        m.radius = radius
        m.name = name
        m.groupName = groupName
        m.locationName = locationName
        m.firstName = firstName
        m.lastName = lastName
        m.phone = phone
        m.streetName = streetName
        m.streetNr = streetNr
        m.zipCode = zipCode
        m.city = city
        m.state = state

        m.lat = lat.value
        m.lng = lng.value
        m.startsAt = startsAt.value
        m.endsAt = endsAt.value
        m.isPrivate = isPrivate.value
        return m
    }
}

class LocationRepo: RealmDataRepo<LocationRealmModel, Location> {
    override func createSaveModel() -> LocationRealmModel {
        return LocationRealmModel()
    }

    init(key: Data) {
        super.init(filenameSalt: "LocationRepo", schemaVersion: 1, migrationBlock: { (migration, schemaVersion) in
            if schemaVersion < 1 {
                migration.enumerateObjects(ofType: LocationRealmModel.className()) { _, newObject in
                    newObject?["isPrivate"] = nil
                }
            }
        }, encryptionKey: key)
    }
}
