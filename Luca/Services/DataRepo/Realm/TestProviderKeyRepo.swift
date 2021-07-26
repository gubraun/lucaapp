import Foundation
import RealmSwift

class TestProviderKeyRealmModel: RealmSaveModel<TestProviderKey> {
    @objc dynamic var name = ""
    @objc dynamic var fingerprint = ""
    @objc dynamic var publicKey = ""

    override func create() -> TestProviderKey {
        return TestProviderKey(name: "", fingerprint: "", publicKey: "")
    }

    override func populate(from: TestProviderKey) {
        super.populate(from: from)
        name = from.name
        fingerprint = from.fingerprint
        publicKey = from.publicKey
    }

    override var model: TestProviderKey {
        var m = super.model
        m.name = name
        m.fingerprint = fingerprint
        m.publicKey = publicKey
        return m
    }

}

class TestProviderKeyRepo: RealmDataRepo<TestProviderKeyRealmModel, TestProviderKey> {

    override func createSaveModel() -> TestProviderKeyRealmModel {
        return TestProviderKeyRealmModel()
    }

    init(key: Data) {
        super.init(filenameSalt: "TestProviderKeyRepo", schemaVersion: 0, encryptionKey: key)
    }

}
