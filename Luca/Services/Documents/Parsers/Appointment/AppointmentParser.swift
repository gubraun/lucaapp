import Foundation
import RxSwift

class AppointmentParser: DocumentParser {
    func parse(code: String) -> Single<Document> {
        Single.create { observer -> Disposable in
            do {
                var parameters = code
                if let index = code.firstIndex(of: "?") {
                    parameters = String(code.suffix(from: index))
                    parameters.removeFirst()
                }
                /// Parse appointment format to json string
                let decodedParameters = parameters.removingPercentEncoding ?? ""
                let jsonString = "{\"" + decodedParameters.replacingOccurrences(of: "&", with: "\",\"").replacingOccurrences(of: "=", with: "\":\"") + "\"}"
                let jsonData = jsonString.data(using: .utf8)!
                let payload = try JSONDecoder().decode(TestAppointmentPayload.self, from: jsonData)

                observer(.success(TestAppointment(payload: payload, originalCode: parameters)))
            } catch {
                observer(.failure(CoronaTestProcessingError.parsingFailed))
            }

            return Disposables.create()
        }
    }
}
