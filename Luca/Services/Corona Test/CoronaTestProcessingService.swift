import Foundation
import RxSwift
import RxRelay
import RealmSwift
import SwiftJWT

class CoronaTestProcessingService {

    private var coronaTestRepoService: CoronaTestRepoService
    private var coronaTestFactory: CoronaTestFactory
    private var disposeBag = DisposeBag()
    private var preferences: LucaPreferences
    private var uniquenessChecker: CoronaTestUniquenessChecker

    // Stores deeplink for delayed presentation
    var deeplinkStore = BehaviorSubject(value: String())

    // Emits everytime there is a data update (deletion, addition) and the table view needs to be updated.
    private var tests = BehaviorSubject(value: [CoronaTest]())

    private var cachedTests: [CoronaTest] {
        return (try? self.tests.value()) ?? []
    }

    var currentAndNewTests: Observable<[CoronaTest]> {
        tests.asObservable()
    }

    init(coronaTestRepoService: CoronaTestRepoService, coronaTestFactory: CoronaTestFactory, preferences: LucaPreferences, uniquenessChecker: CoronaTestUniquenessChecker) {
        self.coronaTestFactory = coronaTestFactory
        self.coronaTestRepoService = coronaTestRepoService
        self.preferences = preferences
        self.uniquenessChecker = uniquenessChecker
        initializeTests()
    }

    /// Filter out invalid QR tests, save, and update validTests with new array of tests
    /// - Parameter qr: Payload from qr tag
    /// - Returns: Completable
    func parseQRCode(qr: String) -> Completable {
        coronaTestFactory.createCoronaTest(from: qr)
            .flatMap(checkIfTestBelongsToCurrentUser)
            .flatMap(checkIfTestIsValid)
            .flatMap(checkIfTestIsNegative)
            .flatMap { test in self.uniquenessChecker.redeem(test: test).andThen(Single.just(test)) }
            .asObservable()
            .asSingle()
            .flatMap { [unowned self] in
                self.coronaTestRepoService.storeTest(test: $0) }
            .flatMap { [unowned self] _ in
                Single.just(self.cachedTests) }
            .flatMap { [unowned self] tests in
                self.coronaTestRepoService.restoreTests(cachedTests: tests)
            }
            .do { self.tests.onNext($0) }
            .asCompletable()
    }

    func deleteTest(identifier: Int) -> Completable {
        coronaTestRepoService.removePayload(with: identifier)
            .andThen(removeDeletedTests(with: identifier))
            .do { self.tests.onNext($0) }
            .asCompletable()
    }

    func initializeTests() {

        Single.just(self.cachedTests)
            .flatMap { [unowned self] tests in
                self.coronaTestRepoService.restoreTests(cachedTests: tests)}
            .flatMap { [unowned self] in
                self.removeInvalidTests(from: $0)
            }
            .flatMap { [unowned self] in
                self.removeUnknownTests(from: $0)
            }
            .subscribe(onSuccess: { [unowned self] tests in
                self.tests.onNext(tests)
            })
            .disposed(by: disposeBag)
    }

    private func removeDeletedTests(with identifier: Int) -> Single<[CoronaTest]> {
        return Single.just(cachedTests.filter { $0.identifier != identifier })
    }

    /// Find invalid tests, delete payloads and update tests array
    /// - Parameter tests: all active tests
    /// - Returns: valid tests
    private func removeInvalidTests(from tests: [CoronaTest]) -> Single<[CoronaTest]> {

        let mappedTests = Observable.from(optional: tests)
            .flatMapLatest {
                Observable.combineLatest($0.map {
                    Observable.combineLatest($0.isValid().asObservable(), Observable.just($0.identifier)) {
                        (isValid: $0, identifier: $1)
                    }
                })
            }

        let invalidIds = mappedTests.map {
            $0.filter { !$0.isValid }
        }
        .map { $0.compactMap { $1 } }

        let validIds = mappedTests.map {
            $0.filter { $0.isValid }
        }
        .map { $0.compactMap { $1 } }

        return invalidIds.flatMap {
            self.coronaTestRepoService.removePayloads(with: $0)
        }.asCompletable()
        .andThen(
            validIds.flatMap { ids in
                Single.just(tests.filter { ids.contains($0.identifier ?? -1)})
            })
        .asSingle()
    }

    private func removeUnknownTests(from tests: [CoronaTest]) -> Single<[CoronaTest]> {
        guard let firstName = preferences.firstName, let lastName = preferences.lastName else {
            return Single.error(CoronaTestProcessingError.nameValidationFailed)
        }

        let invalidNameTests = tests.filter { !$0.belongsToUser(withFirstName: firstName, lastName: lastName) }

        let invalidNameIds = invalidNameTests.map { $0.identifier }.filter { $0 != nil }.map { $0! }
        let validTests = tests.filter { !invalidNameIds.contains($0.identifier!) }

        return self.coronaTestRepoService.removePayloads(with: Array(invalidNameIds))
            .andThen(Single.just(validTests))
    }

    private func checkIfTestBelongsToCurrentUser(test: CoronaTest) -> Single<CoronaTest> {
        Single.create { observer -> Disposable in
            if let firstName = self.preferences.firstName,
               let lastName = self.preferences.lastName,
                  test.belongsToUser(withFirstName: firstName, lastName: lastName) {
                observer(.success(test))
            } else {
                observer(.failure(CoronaTestProcessingError.validationFailed))
            }
            return Disposables.create()
        }
    }

    private func checkIfTestIsValid(test: CoronaTest) -> Single<CoronaTest> {
        test.isValid().asObservable()
            .flatMap { isValid -> Single<CoronaTest> in
                if isValid {
                    return Single.just(test)
                } else {
                    return Single.error(CoronaTestProcessingError.expired)
                }
            }.asSingle()
    }

    private func checkIfTestIsNegative(test: CoronaTest) -> Single<CoronaTest> {
        Single.create { observer -> Disposable in
            if test.isNegative {
                observer(.success(test))
            } else {
                observer(.failure(CoronaTestProcessingError.positiveTest))
            }
            return Disposables.create()
        }
    }
}

enum CoronaTestProcessingError: LocalizedTitledError {
    case parsingFailed
    case validationFailed
    case verificationFailed
    case nameValidationFailed
    case expired
    case positiveTest
}

extension CoronaTestProcessingError {
    var errorDescription: String? {
        switch self {
        case .parsingFailed: return L10n.Test.Result.Parsing.error
        case .validationFailed: return L10n.Test.Result.Validation.error
        case .verificationFailed: return L10n.Test.Result.Verification.error
        case .nameValidationFailed: return L10n.Test.Result.Name.Validation.error
        case .expired: return L10n.Test.Result.Expiration.error
        case .positiveTest: return L10n.Test.Result.Positive.error
        }
    }

    var localizedTitle: String {
        switch self {
        case .verificationFailed: return L10n.Test.Result.Verification.error
        default:
            return L10n.Navigation.Basic.error
        }
    }
}

class CoronaTestDeeplinkService {

    static let deeplinkNotificationName = Notification.Name("DidOpenTestDeeplink")
    static let deeplinkTestPrefix = "https://app.luca-app.de/webapp/testresult/#"

    static func postDeeplinkNotification(test: String) {
        NotificationCenter.default.post(Notification(name: Self.deeplinkNotificationName,
                                                    object: nil,
                                                    userInfo: ["test": test]))
    }

}
