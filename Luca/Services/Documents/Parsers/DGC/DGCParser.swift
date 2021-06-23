import Foundation
import RxSwift
import SwiftDGC

class DGCParser: DocumentParser {
    func parse(code: String) -> Single<Document> {
        Single.create { observer -> Disposable in
            // Remove URL if present
            var parameters = code
            if let index = code.firstIndex(of: "#") {
                parameters = String(code.suffix(from: index))
                parameters.removeFirst()
            }

            if let hCert = HCert(from: parameters) {

                let dgcCert = DGCCert(hCert: hCert)

                switch hCert.type {
                case .test:
                    if let dgcTest = dgcCert.testStatements.first {
                        observer(.success(DGCCoronaTest(cert: dgcCert, test: dgcTest, originalCode: parameters)))
                    }
                case .vaccine:
                    if let dgcVaccine = dgcCert.vaccineStatements.first {
                        observer(.success(DGCVaccination(cert: dgcCert, vaccine: dgcVaccine, originalCode: parameters)))
                    }
                default:
                    observer(.failure(CoronaTestProcessingError.parsingFailed))
                }
                observer(.failure(CoronaTestProcessingError.parsingFailed))
            } else {
                observer(.failure(CoronaTestProcessingError.parsingFailed))
            }

            return Disposables.create()
        }
    }
}
