import XCTest
@testable import Luca_Debug

class CoronaTestUniquenessCheckerTests: XCTestCase {

    // swiftlint:disable:next line_length
    private let encodedJWT = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJ2IjoyLCJuIjoiYTZhODVkODUyZTA1OTFkZjM2ODUwZTFmMDc1MTFkZWE0MmFjYjAxMjljNzFkZjk1ZTM2YWVkNzhkYWU5ZTNhOCIsInQiOjE2MjAyNzU3NDAsImMiOiJwIiwiciI6InAiLCJsIjoiQ292aW1lZGljYWwgR21iSCIsImQiOiJQcm9mLiBIYW5zIiwiZWQiOiJpTHhpSFZzck5oZFh6UDNoeEZkd1p3Z1ludDVGTUYzVXo3MmJHOHMxcytxV2hzZEgxeGJ4R1Z0SHZzbVwvZkRLXC9zWUczdVwvR0pKd3BXTldSZ2xHOGs0SnhyKytCeDBwWStudjlqb0diWm5lWEt4Ulp6T3RSWnlxeEY2cExrIn0.WocR6aa8EX1WEOKxES_gFnvfJnrg6xLzm1cwZ453StqubQPlMjG-JdZofVa4NgTRUCrxDvcQd8M-wQxksM79Dpy0_tOP2mHA59V5LTsVSVzk7teS6cTGhy1nGqZIfu3ORvOqTvxJmuBtT-Z8TGnJzkTTMNx_t8mPSBTHCJX9YQE0APXSnusiy5LF4iQTpYrgKEH0IZTT4gIx6-SbNpkuVmJE6RxVvjAdnlnTS6lqtr9jplaNw8L6gDw5s0zZ5z8xytuWvceRap_GOTeCxdmg-8f4EghjMJFea8T5WwfZY4BDJbEawsAcOY-ErS4Ey3M_W8PYaPTZWmClOiJGsCeU8w"

    private var emptyTest = JWTTestPayload(
        claims: JWTTestClaims(
            version: 0,
            name: "",
            time: 0,
            category: Category.other,
            result: Result.positive,
            lab: "",
            doctor: ""),
        originalCode: ""
    )

    private var uniquenessChecker: DocumentUniquenessChecker!

    override func setUpWithError() throws {
        uniquenessChecker = DocumentUniquenessChecker(
            backend: BackendMiscV3(backendAddress: BackendAddressV3()),
            keyValueRepo: EmptyKeyValueRepoMock()
        )
    }

    func testEncodedJWTHash_isCorrect() {
        let hash = "rP72MQSq4AY5WWd+jMdepPpFxoJvq+UOzgSu6EaAhSw="
        emptyTest.originalCode = encodedJWT

        do {
            let hashResult = try uniquenessChecker.generateHash(for: emptyTest)
            XCTAssertEqual(hashResult.base64EncodedString(), hash)
        } catch {
            XCTAssert(false)
        }
    }

}

class EmptyKeyValueRepoMock: KeyValueRepoProtocol {
    func removeAll(completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) {
        fatalError()
    }

    func remove(_ key: String, completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) {
        fatalError()
    }

    func load<T>(_ key: String, type: T.Type, completion: @escaping ((T) -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) where T: Decodable {
        fatalError()
    }

    func store<T>(_ key: String, value: T, completion: @escaping (() -> Void), failure: @escaping ((LocalizedTitledError) -> Void)) where T: Encodable {
        fatalError()
    }
}
