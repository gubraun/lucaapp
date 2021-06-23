import Foundation
import RxSwift

enum DocumentUniquenessCheckerError: LocalizedTitledError {

    case failedToCreateRandomTag
    case encodingFailed

}

extension DocumentUniquenessCheckerError {

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

/// Guarantees that a document is unique in the Luca system.
class DocumentUniquenessChecker {
    private let key = "testRedeemCheck".data(using: .utf8)!
    private let backend: BackendMiscV3
    private let storage: KeyValueRepoProtocol

    init(backend: BackendMiscV3, keyValueRepo: KeyValueRepoProtocol) {
        self.backend = backend
        self.storage = keyValueRepo
    }

    func redeem(document: Document) -> Completable {
        let generateHash = Single.from {
            try self.generateHash(for: document)
        }
        return Single.zip(generateHash, getOrCreateTag(for: document)) { (hash, tag) in
            self.backend.redeemDocument(hash: hash, tag: tag).asCompletable()
        }
        .flatMapCompletable { $0 }
    }

    func generateHash(for document: Document) throws -> Data {
        let identifier = document.originalCode

        guard let data = identifier.data(using: .utf8) else {
            throw DocumentUniquenessCheckerError.encodingFailed
        }

        let hmac = HMACSHA256(key: key)
        return try hmac.encrypt(data: data)
    }

    private func getOrCreateTag(for document: Document) -> Single<Data> {
        getTag(for: document).ifEmpty(switchTo: createAndStoreTag(for: document))
    }

    private func createAndStoreTag(for document: Document) -> Single<Data> {
        Single.from {
            guard let tag = KeyFactory.randomBytes(size: 16) else {
                throw DocumentUniquenessCheckerError.failedToCreateRandomTag
            }
            return tag
        }
        .flatMap { self.storage.store(self.tagKey(for: document), value: $0).andThen(Single.just($0)) }
    }

    private func getTag(for document: Document) -> Maybe<Data> {
        storage.load(tagKey(for: document), type: Data.self)
            .asMaybe()
            .catch { _ in Maybe.empty() }
    }

    private func tagKey(for document: Document) -> String {
        let identifier = document.identifier
        let checksum = identifier.data.crc32
        return "importedTestTag.\(checksum)"
    }
}
