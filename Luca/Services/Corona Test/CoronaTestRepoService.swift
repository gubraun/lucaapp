import Foundation
import RxSwift
import RealmSwift

class CoronaTestRepoService {
    private var coronaTestRepo: CoronaTestRepo
    private var coronaTestFactory: CoronaTestFactory
    private var disposeBag = DisposeBag()

    init(coronaTestRepo: CoronaTestRepo, coronaTestFactory: CoronaTestFactory) {
        self.coronaTestRepo = coronaTestRepo
        self.coronaTestFactory = coronaTestFactory
    }

    func storeTest(test: CoronaTest) -> Single<CoronaTest> {
        Single<CoronaTest>.create { (observer) -> Disposable in
            var payload = CoronaTestPayload(originalCode: test.originalCode)
            payload.identifier = test.identifier
            self.coronaTestRepo.store(object: payload) { (_) in
                observer(.success(test))
            } failure: { (error) in
                observer(.failure(error))
            }

            return Disposables.create()
        }
    }

    func restoreTests(cachedTests: [CoronaTest]) -> Single<[CoronaTest]> {
        restorePayloads()
            .flatMap {  [unowned self] in
                self.filterNewPayloads(with: $0, cachedTests: cachedTests) }
            .flatMap { [unowned self] in
                self.updateTests(with: $0, cachedTests: cachedTests) }
    }

    private func restorePayloads() -> Single<[CoronaTestPayload]> {
        Single<[CoronaTestPayload]>.create { (observer) -> Disposable in
            self.coronaTestRepo.restore { (restored) in
                observer(.success(restored))
            } failure: { (error) in
                observer(.failure(error))
            }

            return Disposables.create()
        }
    }

    /// Filters payloads to find ones that are not parsed and cached yet
    /// - Parameter payloads: all payloads from repo
    /// - Parameter cachedTests: existing cached tests
    /// - Returns: new payloads to be cached
    private func filterNewPayloads(with payloads: [CoronaTestPayload], cachedTests: [CoronaTest]) -> Single<[CoronaTestPayload]> {
        Single<[CoronaTestPayload]>.create { (observer) -> Disposable in
                let cachedTestIds = cachedTests.compactMap { $0.identifier }
                let newTestPayloads = payloads.filter { !cachedTestIds.contains($0.identifier ?? -1) }
                observer(.success(newTestPayloads))
            return Disposables.create()
        }
    }

    /// Parse and add new tests to existing cached ones
    /// - Parameter payloads: new payloads
    /// - Parameter cachedTests: existing cached tests
    /// - Returns: new parsed [CoronaTest]
    private func updateTests(with payloads: [CoronaTestPayload], cachedTests: [CoronaTest]) -> Single<[CoronaTest]> {
        var newTests = payloads.compactMap { self.coronaTestFactory.createCoronaTest(from: $0.originalCode )}

        let mappedCachedTests = cachedTests.map { Single.just($0) }
        newTests.append(contentsOf: mappedCachedTests)

        return Observable.from(newTests)
            .merge()
            .toArray()
    }

    func removePayloads(with identifiers: [Int]) -> Completable {
        return self.coronaTestRepo.remove(identifiers: identifiers)
    }

    func removePayload(with identifier: Int) -> Completable {
        return removePayloads(with: [identifier])
    }
}
