import Foundation
import Alamofire

class AlamofireLogger: EventMonitor {

    private let logger = GeneralPurposeLog(
        subsystem: "App",
        category: "Alamofire",
        subDomains: [Data(UUID().bytes.prefix(4)).toHexString()]
    )

    func requestDidResume(_ request: Request) {
        let body = request.request.flatMap { $0.httpBody.map { String(decoding: $0, as: UTF8.self) } } ?? "None"
        logger.log("Started \(request)", entryType: .info)
        logger.log("Body data \(body)", entryType: .info)
    }

    func request(_ request: DataRequest, didParseResponse response: DataResponse<Data?, AFError>) {
        logger.log("Response status code: \(response.response?.statusCode ?? -1)", entryType: .info)
        if let error = response.error {
            logger.log("Error: \(error)", entryType: .error)
        }
        if let data = response.data,
           let text = String(data: data, encoding: .utf8) {
            logger.log("Response received: \(text)", entryType: .info)
        }
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: AFDataResponse<Value>) {
        logger.log("Response status code: \(response.response?.statusCode ?? -1)", entryType: .info)
        if let error = response.error {
            logger.log("Error: \(error)", entryType: .error)
        }
        if let data = response.data,
           let text = String(data: data, encoding: .utf8) {
            logger.log("Response received: \(text)", entryType: .info)
        }
    }
}
