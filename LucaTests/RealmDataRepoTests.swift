// import XCTest
// import RealmSwift
// import RxSwift
// import RxBlocking
// @testable import Luca_Debug
//
// class RealmDataRepoTests: XCTestCase {
//
//    // Both repos work on the same file, so accessing the same file should always produce errors as the encryption settings are different
//    var repo: SomeDatasetRepo!
//    var encryptedRepo: SomeDatasetEncryptedRepo!
//    let singleInputData = SomeDataset(identifier: 0, someString: "some string", someInt: 1234, someArray: [2345, 456, 235], someOptional: "ih9")
//    let multipleInputData = [
//        SomeDataset(identifier: 0, someString: "some string", someInt: 1234, someArray: [2345, 456, 235], someOptional: "ih9"),
//        SomeDataset(identifier: 1, someString: "some string 123 ", someInt: 213, someArray: [2345, 235], someOptional: nil)
//    ]
//    let timeout: TimeInterval = 3.0
//
//    override func setUpWithError() throws {
//        repo = SomeDatasetRepo()
//        encryptedRepo = SomeDatasetEncryptedRepo()
//        _ = try repo.removeFile().toBlocking().toArray()
//
//        continueAfterFailure = false
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func test_writeAndReadSingleDataSet_loadedDataSetEqualsOrigin() throws {
//        try writeAndReadSingleDataSet_loadedDataSetEqualsOrigin(with: repo)
//    }
//
//    func test_writeAndReadEncryptedSingleDataSet_loadedDataSetEqualsOrigin() throws {
//        try writeAndReadSingleDataSet_loadedDataSetEqualsOrigin(with: encryptedRepo)
//    }
//
//    func test_writeAndReadMultipleDataSet_loadedDataSetEqualsOrigin() throws {
//        try writeAndReadMultipleDataSet_loadedDataSetEqualsOrigin(with: repo)
//    }
//
//    func test_writeAndReadEncryptedMultipleDataSet_loadedDataSetEqualsOrigin() throws {
//        try writeAndReadMultipleDataSet_loadedDataSetEqualsOrigin(with: encryptedRepo)
//    }
//
//    func test_writeAndRemoveAllData_restoresEmptyArray() {
//        writeAndRemoveAllData_restoresEmptyArray(with: repo)
//    }
//
//    func test_encrypted_writeAndRemoveAllData_restoresEmptyArray() {
//        writeAndRemoveAllData_restoresEmptyArray(with: encryptedRepo)
//    }
//
//    func test_writeMultipleDataAndRemoveOneObject_restoresSingleItem() {
//        writeMultipleDataAndRemoveOneObject_restoresSingleItem(with: repo)
//    }
//
//    func test_encrypted_writeMultipleDataAndRemoveOneObject_restoresSingleItem() {
//        writeMultipleDataAndRemoveOneObject_restoresSingleItem(with: encryptedRepo)
//    }
//
//    func test_writeNonEncryptedAndLoadWithKey_fails() {
//        let failExpectation = XCTestExpectation(description: "Failed on restore")
//        let readExpectation = XCTestExpectation(description: "Actually read data")
//        readExpectation.isInverted = true
//
//        _ = repo.store(object: singleInputData)
//            .flatMap { _ in
//                self.encryptedRepo.restore()
//                .do(onSuccess: { _ in readExpectation.fulfill() })
//                .do(onError: { _ in failExpectation.fulfill() })
//            }
//            .catchAndReturn([])
//            .subscribe()
//
//        wait(for: [failExpectation, readExpectation], timeout: timeout)
//    }
//
//    func test_writeEncryptedAndLoadWithNoKey_fails() {
//        let failExpectation = XCTestExpectation(description: "Failed on restore")
//        let readExpectation = XCTestExpectation(description: "Actually read data")
//        readExpectation.isInverted = true
//
//        _ = encryptedRepo.store(object: singleInputData)
//            .flatMap { _ in
//                self.repo.restore()
//                .do(onSuccess: { _ in readExpectation.fulfill() })
//                .do(onError: { _ in failExpectation.fulfill() })
//            }
//            .catchAndReturn([])
//            .subscribe()
//
//        wait(for: [failExpectation, readExpectation], timeout: timeout)
//    }
//
//    func test_changeNonEncryptedToEncrypted_readEncrypted() {
//        let readExpectation = XCTestExpectation(description: "Read data")
//
//        _ = repo.store(object: singleInputData)
//            .flatMapCompletable { _ in self.repo.changeEncryptionSettings(oldKey: nil, newKey: encryptionKey) }
//            .andThen(encryptedRepo.restore())
//            .do(onSuccess: { restored in
//                if restored.count == 1 && restored.first == self.singleInputData {
//                    readExpectation.fulfill()
//                }
//            })
//            .subscribe()
//
//        wait(for: [readExpectation], timeout: timeout)
//    }
//
//    func test_changeNonEncryptedToEncrypted_failAtReadNonEncrypted() {
//        let failExpectation = XCTestExpectation(description: "Failed on restore")
//        let readExpectation = XCTestExpectation(description: "Read data")
//        readExpectation.isInverted = true
//
//        _ = repo.store(object: singleInputData)
//            .flatMapCompletable { _ in self.repo.changeEncryptionSettings(oldKey: nil, newKey: encryptionKey) }
//            .andThen(repo.restore())
//            .do(onSuccess: { restored in
//                if restored.count > 0 {
//                    readExpectation.fulfill()
//                }
//            })
//            .do(onError: { _ in
//                failExpectation.fulfill()
//            })
//            .subscribe()
//
//        wait(for: [readExpectation, failExpectation], timeout: timeout)
//    }
//
//    func test_changeEncryptedToNonEncrypted_read() {
//        let readExpectation = XCTestExpectation(description: "Read data")
//
//        _ = encryptedRepo.store(object: singleInputData)
//            .flatMapCompletable { _ in self.repo.changeEncryptionSettings(oldKey: encryptionKey, newKey: nil) }
//            .andThen(repo.restore())
//            .do(onSuccess: { restored in
//                if restored.count == 1 && restored.first == self.singleInputData {
//                    readExpectation.fulfill()
//                }
//            })
//            .subscribe()
//
//        wait(for: [readExpectation], timeout: timeout)
//    }
//
//    func test_changeEncryptedToNonEncrypted_failAtReadEncrypted() {
//        let failExpectation = XCTestExpectation(description: "Failed on restore")
//        let readExpectation = XCTestExpectation(description: "Read data")
//        readExpectation.isInverted = true
//
//        _ = encryptedRepo.store(object: singleInputData)
//            .flatMapCompletable { _ in self.repo.changeEncryptionSettings(oldKey: encryptionKey, newKey: nil) }
//            .andThen(encryptedRepo.restore())
//            .do(onSuccess: { restored in
//                if restored.count > 0 {
//                    readExpectation.fulfill()
//                }
//            })
//            .do(onError: { _ in
//                failExpectation.fulfill()
//            })
//            .subscribe()
//
//        wait(for: [readExpectation, failExpectation], timeout: timeout)
//    }
//
//    private func writeAndReadSingleDataSet_loadedDataSetEqualsOrigin(with selectedRepo: RealmDataRepo<SomeDatasetRealmModel, SomeDataset>) throws {
//        let writeExpectation = XCTestExpectation(description: "Write data set")
//        let readExpectation = XCTestExpectation(description: "Read data set")
//
//        _ = selectedRepo.store(object: singleInputData)
//            .flatMap { writtenObject in
//                if writtenObject == self.singleInputData {
//                    writeExpectation.fulfill()
//                }
//                return selectedRepo.restore().map { $0.first }.unwrapOptional()
//            }
//            .map { $0 == self.singleInputData }
//            .filter { $0 }
//            .do(onNext: { _ in readExpectation.fulfill() })
//            .subscribe()
//
//        wait(for: [writeExpectation, readExpectation], timeout: timeout)
//    }
//
//    private func writeAndReadMultipleDataSet_loadedDataSetEqualsOrigin(with selectedRepo: RealmDataRepo<SomeDatasetRealmModel, SomeDataset>) throws {
//        let writeExpectation = XCTestExpectation(description: "Write data set")
//        let readExpectation = XCTestExpectation(description: "Read data set")
//
//        _ = selectedRepo.store(objects: multipleInputData)
//            .flatMap { writtenObjects in
//                if writtenObjects == self.multipleInputData {
//                    writeExpectation.fulfill()
//                }
//                return selectedRepo.restore()
//            }
//            .map { $0 == self.multipleInputData }
//            .filter { $0 }
//            .do(onNext: { _ in readExpectation.fulfill() })
//            .subscribe()
//
//        wait(for: [writeExpectation, readExpectation], timeout: timeout)
//    }
//
//    private func writeAndRemoveAllData_restoresEmptyArray(with selectedRepo: RealmDataRepo<SomeDatasetRealmModel, SomeDataset>) {
//        let readEmptyExpectation = XCTestExpectation(description: "Read empty data set")
//
//        _ = selectedRepo.store(objects: multipleInputData)
//            .flatMapCompletable { _ in selectedRepo.removeAll() }
//            .andThen(selectedRepo.restore())
//            .do(onSuccess: { restored in
//                if restored.count == 0 {
//                    readEmptyExpectation.fulfill()
//                }
//            })
//            .subscribe()
//        wait(for: [readEmptyExpectation], timeout: timeout)
//    }
//
//    private func writeMultipleDataAndRemoveOneObject_restoresSingleItem(with selectedRepo: RealmDataRepo<SomeDatasetRealmModel, SomeDataset>) {
//        let readSingleExpectation = XCTestExpectation(description: "Read single object")
//
//        _ = selectedRepo.store(objects: multipleInputData)
//            .flatMapCompletable { _ in selectedRepo.remove(identifiers: [0]) }
//            .andThen(selectedRepo.restore())
//            .do(onSuccess: { restored in
//                if restored.count == 1 && restored.first == self.multipleInputData[1] {
//                    readSingleExpectation.fulfill()
//                }
//            })
//            .subscribe()
//        wait(for: [readSingleExpectation], timeout: timeout)
//    }
// }
//
// struct SomeDataset: DataRepoModel, Equatable {
//
//    var identifier: Int?
//
//    var someString: String
//    var someInt: Int
//    var someArray: [Int]
//    var someOptional: String?
//
// }
//
// class SomeDatasetRealmModel: RealmSaveModel<SomeDataset> {
//
//    @objc dynamic var someString = ""
//    @objc dynamic var someInt = 0
//    var someArray = List<Int>()
//
//    @objc dynamic var someOptional: String?
//
//    override func create() -> SomeDataset {
//        return SomeDataset(identifier: nil, someString: "", someInt: 0, someArray: [], someOptional: nil)
//    }
//
//    override func populate(from: SomeDataset) {
//        super.populate(from: from)
//        someString = from.someString
//        someInt = from.someInt
//        someArray.removeAll()
//        someArray.append(objectsIn: from.someArray)
//        someOptional = from.someOptional
//    }
//
//    override var model: SomeDataset {
//        var m = super.model
//        m.someArray = Array(someArray)
//        m.someString = someString
//        m.someInt = someInt
//        m.someOptional = someOptional
//        return m
//    }
// }
//
// class SomeDatasetRepo: RealmDataRepo<SomeDatasetRealmModel, SomeDataset> {
//
//    override func createSaveModel() -> SomeDatasetRealmModel {
//        return SomeDatasetRealmModel()
//    }
//
//    init() {
//        super.init(filenameSalt: "TestRepo", schemaVersion: 0)
//    }
// }
//
// let encryptionKey = Data(hex: "a0f9ca456622c28dba9827d75f78de541dd05e4a807770bbe2cf8dedd307d45d3b754e78ebc5345efacfaa6ed815c4930bf4f8a9ed8069ff88956b6696e4767a")
// class SomeDatasetEncryptedRepo: RealmDataRepo<SomeDatasetRealmModel, SomeDataset> {
//
//    override func createSaveModel() -> SomeDatasetRealmModel {
//        return SomeDatasetRealmModel()
//    }
//
//    init() {
//        super.init(filenameSalt: "TestRepo", schemaVersion: 0, encryptionKey: encryptionKey)
//    }
// }
