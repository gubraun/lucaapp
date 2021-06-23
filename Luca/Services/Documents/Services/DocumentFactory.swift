import Foundation
import RxSwift
import RealmSwift

/// Parses serialized strings to `Document` instances with registered parsers
class DocumentFactory {

    private var parsers: [DocumentParser] = []

    func register(parser: DocumentParser) {
        parsers.append(parser)
    }

    func createDocument(from code: String) -> Single<Document> {

        let observables = parsers
            .map { $0.parse(code: code)
                .asObservable()
                .onErrorComplete()
            }

        return Observable.concat(observables)
            .take(1)
            .asSingle()
            .catch { _ in Single.error(CoronaTestProcessingError.parsingFailed) }
    }

}
