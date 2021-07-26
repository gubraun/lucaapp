import Foundation
import RxSwift
import RxRelay
import RealmSwift
import SwiftJWT

/// Tool for document parsing, running validation logic and guaranteing the uniqueness of imported document
class DocumentProcessingService {
    private let documentFactory: DocumentFactory
    private var documentRepoService: DocumentRepoService
    private var disposeBag = DisposeBag()
    private var uniquenessChecker: DocumentUniquenessChecker

    private var documentValidators: [DocumentValidator] = []

    let deeplinkPrefixArray = ["https://app.luca-app.de/webapp/testresult/#",
                               "https://app.luca-app.de/webapp/appointment/?"]

    /// Captured deep links
    let deeplinkStore = BehaviorSubject(value: String())

    init(documentRepoService: DocumentRepoService, documentFactory: DocumentFactory, uniquenessChecker: DocumentUniquenessChecker) {

        self.documentFactory = documentFactory
        self.documentRepoService = documentRepoService
        self.uniquenessChecker = uniquenessChecker
    }

    func register(validator: DocumentValidator) {
        documentValidators.append(validator)
    }

    /// Filter out invalid QR tests, save, and update validTests with new array of tests
    /// - Parameter qr: Payload from qr tag
    /// - Returns: Completable
    func parseQRCode(qr: String) -> Completable {
        documentFactory.createDocument(from: qr)
            .flatMap { self.validate($0).andThen(Single.just($0)) }
            .flatMap {
                #if PREPROD || PRODUCTION
                self.uniquenessChecker.redeem(document: $0).andThen(Single.just($0))
                #else
                Single.just($0)
                #endif
            }
            .asObservable()
            .asSingle()
            .flatMap { [unowned self] in
                self.documentRepoService.store(document: $0).andThen(Single.just($0))
            }
            .asCompletable()
    }

    private func validate(_ document: Document) -> Completable {
        Completable.zip(documentValidators.map { $0.validate(document: document) })
    }

    func revalidateSavedTests() -> Completable {
        documentRepoService.load()
            .asObservable()
            .flatMap { Observable.from($0) }
            .flatMap { document in
                self.validate(document).catch { _ in self.documentRepoService.remove(identifier: document.identifier) }
            }
            .ignoreElementsAsCompletable()
    }
}

enum CoronaTestProcessingError: LocalizedTitledError {
    case parsingFailed
    case validationFailed
    case verificationFailed
    case nameValidationFailed
    case expired
    case positiveTest
    case noIssuer
}

extension CoronaTestProcessingError {
    var errorDescription: String? {
        switch self {
        case .parsingFailed: return L10n.Test.Result.Parsing.error
        case .validationFailed: return L10n.Test.Result.Validation.error
        case .verificationFailed: return L10n.Test.Result.Verification.error
        case .noIssuer: return L10n.Test.Result.Verification.error
        case .nameValidationFailed: return L10n.Test.Result.Name.Validation.error
        case .expired: return L10n.Test.Result.Expiration.error
        case .positiveTest: return L10n.Test.Result.Positive.error
        }
    }

    var localizedTitle: String {
        switch self {
        case .verificationFailed: return L10n.Test.Result.Verification.error
        default:
            return L10n.Test.Result.Error.title
        }
    }
}
