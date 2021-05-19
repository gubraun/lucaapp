import Foundation
import RxSwift

enum CoronaTestUniquenessCheckerError: LocalizedTitledError {

    case failedToCreateRandomTag
    case encodingFailed

}

extension CoronaTestUniquenessCheckerError {

    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }

    var errorDescription: String? {
        switch self {
        case .failedToCreateRandomTag: return L10n.Test.Uniqueness.Create.RandomTag.error
        case .encodingFailed: return L10n.Test.Uniqueness.Encoding.error
        }
    }

}

class CoronaTestUniquenessChecker {
    private let key = "testRedeemCheck".data(using: .utf8)!
    private let backend: BackendMiscV3
    private let storage: KeyValueRepoProtocol

    init(backend: BackendMiscV3, keyValueRepo: KeyValueRepoProtocol) {
        self.backend = backend
        self.storage = keyValueRepo
    }

    func redeem(test: CoronaTest) -> Completable {
        let generateHash = Single.from {
            try self.generateHash(for: test)
        }
        return Single.zip(generateHash, getOrCreateTag(for: test)) { (hash, tag) in
            self.backend.redeemCoronaTest(hash: hash, tag: tag).asCompletable()
        }
        .flatMapCompletable { $0 }
    }

    func generateHash(for test: CoronaTest) throws -> Data {
        let identifier = test.originalCode

        guard let data = identifier.data(using: .utf8) else {
            throw CoronaTestUniquenessCheckerError.encodingFailed
        }

        let hmac = HMACSHA256(key: key)
        return try hmac.encrypt(data: data)
    }

    private func getOrCreateTag(for test: CoronaTest) -> Single<Data> {
        getTag(for: test).ifEmpty(switchTo: createAndStoreTag(for: test))
    }

    private func createAndStoreTag(for test: CoronaTest) -> Single<Data> {
        Single.from {
            guard let tag = KeyFactory.randomBytes(size: 16) else {
                throw CoronaTestUniquenessCheckerError.failedToCreateRandomTag
            }
            return tag
        }
        .flatMap { self.storage.store(self.tagKey(for: test), value: $0).andThen(Single.just($0)) }
    }

    private func getTag(for test: CoronaTest) -> Maybe<Data> {
        storage.load(tagKey(for: test), type: Data.self)
            .asMaybe()
            .catch { _ in Maybe.empty() }
    }

    private func tagKey(for test: CoronaTest) -> String {
        let identifier = test.identifier ?? -1
        let checksum = identifier.data.crc32
        return "importedTestTag.\(checksum)"
    }
}
