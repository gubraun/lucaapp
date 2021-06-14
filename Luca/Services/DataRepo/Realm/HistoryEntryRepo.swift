import Foundation
import RealmSwift

class HistoryEntryRealmModel: RealmSaveModel<HistoryEntry> {

    @objc dynamic var date = Date()
    @objc dynamic var type = ""
    @objc dynamic var location: Data?
    @objc dynamic var role: Data?
    @objc dynamic var guestlist: Data?

    override func create() -> HistoryEntry {
        return HistoryEntry(date: Date(), type: .checkIn, location: nil)
    }

    override func populate(from: HistoryEntry) {
        super.populate(from: from)
        date = from.date
        type = from.type.rawValue
        location = nil
        role = nil
        guestlist = nil

        let jsonEncoder = JSONEncoder()
        if let location = from.location,
           let serialized = try? jsonEncoder.encode(location) {
            self.location = serialized
        }

        if let role = from.role,
           let serialized = try? jsonEncoder.encode(role) {
            self.role = serialized
        }
        if let guestlist = from.guestlist,
           let serialized = try? jsonEncoder.encode(guestlist) {
            self.guestlist = serialized
        }
    }

    override var model: HistoryEntry {
        var m = super.model
        m.date = date
        m.type = HistoryEntryType(rawValue: type) ?? .checkIn

        let jsonDecoder = JSONDecoder()

        if let location = self.location,
           let deserialized = try? jsonDecoder.decode(Location.self, from: location) {
            m.location = deserialized
        }

        if let role = self.role,
           let deserialized = try? jsonDecoder.decode(Role.self, from: role) {
            m.role = deserialized
        }

        if let guestlist = self.guestlist,
           let deserialized = try? jsonDecoder.decode([String].self, from: guestlist) {
            m.guestlist = deserialized
        }
        return m
    }
}

class HistoryRepo: RealmDataRepo<HistoryEntryRealmModel, HistoryEntry> {
    override func createSaveModel() -> HistoryEntryRealmModel {
        return HistoryEntryRealmModel()
    }

    init(key: Data) {
        super.init(filenameSalt: "HistoryRepo", schemaVersion: 0, encryptionKey: key)
    }
}
