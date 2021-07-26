import Foundation
import RxSwift

enum DocumentKeyProviderError: LocalizedTitledError {
    case keyNotFound
}

extension DocumentKeyProviderError {
    var localizedTitle: String {
        L10n.Navigation.Basic.error
    }

    var errorDescription: String? {
        "\(self)" // TODO: localization needed
    }
}

class DocumentKeyProvider {

    private let backend: BackendMiscV3
    private let repo: TestProviderKeyRepo

    private var alreadyDownloaded: Bool = false

    init(backend: BackendMiscV3, testProviderKeyRepo: TestProviderKeyRepo) {
        self.backend = backend
        repo = testProviderKeyRepo
    }

    func get(with fingerprint: String) -> Single<TestProviderKey> {
        getFromRepo(fingerprint: fingerprint)
            .catch { _ in self.fetchAndSaveKeys().andThen(self.getFromRepo(fingerprint: fingerprint)) }
    }

    func getAll() -> Single<[TestProviderKey]> {
        Single.from { self.alreadyDownloaded }
            .flatMapCompletable {
                if !$0 {
                    return self.fetchAndSaveKeys()
                        .andThen(Completable.from { self.alreadyDownloaded = true })
                }
                return Completable.empty()
            }
            .andThen(repo.restore())
    }

    private func getFromRepo(fingerprint: String) -> Single<TestProviderKey> {
        repo.restore()
            .map { keys in keys.filter { $0.fingerprint == fingerprint }.first }
            .unwrapOptional()
            .catch { _ in Single.error(DocumentKeyProviderError.keyNotFound) }
    }

    private func fetchAndSaveKeys() -> Completable {
        backend.fetchTestProviderKeys()
            .asSingle()
            .flatMap(repo.store)
            .asCompletable()
    }
}
