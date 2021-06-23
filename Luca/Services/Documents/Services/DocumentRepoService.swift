import Foundation
import RxSwift
import RealmSwift

/// Intermediate layer between raw document payload and the rest of the logic.
/// Uses `DocumentFactory` to retrieve `Document` instances from saved strings
class DocumentRepoService {
    private var documentRepo: DocumentRepo
    private var documentFactory: DocumentFactory
    private var disposeBag = DisposeBag()

    private let cachedDocuments = BehaviorSubject<[Int: Document]>(value: [:])
    private let cacheScheduler = SerialDispatchQueueScheduler(qos: .userInteractive)

    /// Emits all saved tests on subscribe and every change
    var currentAndNewTests: Observable<[Document]> {
        cachedDocuments
            .asObservable()
            .delay(.milliseconds(1), scheduler: cacheScheduler)
            .flatMap { _ in self.load() }
    }

    init(documentRepo: DocumentRepo, documentFactory: DocumentFactory) {
        self.documentRepo = documentRepo
        self.documentFactory = documentFactory
    }

    func store(document: Document) -> Completable {
        Single.from { DocumentPayload(originalCode: document.originalCode, identifier: document.identifier) }
        .flatMap(self.documentRepo.store)
        .flatMapCompletable { self.addToCache(document: document, with: $0.identifier ?? 0) }
    }

    func load() -> Single<[Document]> {
        documentRepo.restore()
            .asObservable()
            .flatMap { payloads in
                Observable.from(payloads)
            }
            .flatMap(getOrParseDocument)
            .toArray()
    }

    func remove(identifier: Int) -> Completable {
        remove(identifiers: [identifier])
    }

    func remove(identifiers: [Int]) -> Completable {
        documentRepo.remove(identifiers: identifiers)
            .andThen(
                Completable.from {
                    var cache = try self.cachedDocuments.value()
                    for key in identifiers {
                        cache.removeValue(forKey: key)
                    }
                    self.cachedDocuments.onNext(cache)
                }
                .subscribe(on: self.cacheScheduler)
            )
    }

    private func getOrParseDocument(from payload: DocumentPayload) -> Single<Document> {
        loadFromCache(identifier: payload.identifier ?? 0)
            .ifEmpty(
                switchTo: parse(payload: payload)
                    .logError(self, "Unparseable document")
                    .flatMap { self.addToCache(document: $0, with: payload.identifier ?? 0).andThen(Single.just($0)) }
            )
    }

    private func addToCache(document: Document, with identifier: Int) -> Completable {
        Completable.from {
            var cache = try self.cachedDocuments.value()
            cache[identifier] = document
            self.cachedDocuments.onNext(cache)
        }
        .subscribe(on: cacheScheduler)
    }

    private func loadFromCache(identifier: Int) -> Maybe<Document> {
        Maybe.from {
            let cache = try self.cachedDocuments.value()
            return cache[identifier]
        }
        .subscribe(on: cacheScheduler)
    }

    private func parse(payload: DocumentPayload) -> Single<Document> {
        documentFactory.createDocument(from: payload.originalCode)
    }
}

extension DocumentRepoService: UnsafeAddress, LogUtil {}
