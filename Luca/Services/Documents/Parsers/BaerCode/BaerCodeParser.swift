import Foundation
import RxSwift

class BaerCodeParser: DocumentParser {
    func parse(code: String) -> Single<Document> {
        // Remove URL if present
        var parameters = code
        if let index = code.firstIndex(of: "#") {
            parameters = String(code.suffix(from: index))
            parameters.removeFirst()
        }

        return BaerCodeDecoder().decodeCode(parameters)
            .flatMap { payload in
                if payload.isVaccine() {
                    return Single.just(BaerCodeVaccination(payload: payload, originalCode: parameters))
                } else {
                    return Single.just(BaerCodeCoronaTest(payload: payload, originalCode: parameters))
                }
            }
            .map { $0 as Document }
    }
}
