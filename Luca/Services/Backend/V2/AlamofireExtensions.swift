import Foundation
import Alamofire

extension DataResponse where Success: Any, Failure: Error {

    var mappingErrors: Error? {
        if let error = self.error as? AFError {
            // Retrieve errors from custom status code mappings
            if case let AFError.responseValidationFailed(reason: reason) = error,
               case let AFError.ResponseValidationFailureReason.customValidationFailed(error: customError) = reason {
                return customError
            }
        }
        return nil
    }

    /// Not nil if:
    /// - custom dict serialization failed
    /// - custom code mapping matched with foreseen error
    var lucaNetworkError: NetworkError? {
        if let error = self.error as? AFError {

            // In case of bad gateway
            if error.responseCode == 502 {
                return NetworkError.badGateway
            }

            // Retrieve errors from custom response serialization
            if case let AFError.responseSerializationFailed(reason: reason) = error,
               case let AFError.ResponseSerializationFailureReason.customSerializationFailed(error: customError) = reason,
               let networkError = customError as? NetworkError {
                return networkError
            }

            // Intercept decoding error when a required key from the model is not found in the response
            if case let AFError.responseSerializationFailed(reason: reason) = error,
               case let AFError.ResponseSerializationFailureReason.decodingFailed(error: dError) = reason,
               let decodingError = dError as? DecodingError,
               case let DecodingError.keyNotFound(key, _) = decodingError {
                return NetworkError.keyNotFound(key: key.stringValue)
            }

            // In case of no network
            if case let AFError.sessionTaskFailed(error: sessionURLError) = error,
               (sessionURLError as NSError).domain == NSURLErrorDomain {
                return NetworkError.noInternet
            }

            // Server trust errors
            if case AFError.serverTrustEvaluationFailed = error {
                // There is a whole set of trust failure reasons. I'll simplify all of them to a failure of the certificate
                return NetworkError.certificateValidationFailed
            }

        }
        return nil
    }
}

extension DataRequest {

    func map(code: Int, to error: Error) -> DataRequest {
        self.validate { (_, response, _) -> ValidationResult in
            if response.statusCode == code {
                return .failure(error)
            }
            return .success(Void())
        }
    }

    @discardableResult
    func responseDict(completion: @escaping ((AFDataResponse<[String: Any]>) -> Void)) -> DataRequest {
        return self.response(responseSerializer: DictSerializer(), completionHandler: completion)
    }

}

extension DataResponse {

    /// Handles all errors into the structure of the `BackendError`
    func retrieveBackendError<T>(_ errorType: T.Type) -> BackendError<T>? where T: RequestError {

        var retVal = BackendError<T>()

        if let mappingError = self.mappingErrors as? T {
            retVal.backendError = mappingError
        } else if let unknownError = self.mappingErrors {
            retVal.networkLayerError = NetworkError.unknown(error: unknownError)
        } else if let networkError = self.lucaNetworkError {
            retVal.networkLayerError = networkError
        } else if let error = self.error {
            retVal.networkLayerError = NetworkError.unknown(error: error)
        }

        if retVal.backendError == nil && retVal.networkLayerError == nil {
            return nil
        }

        return retVal
    }

    /// It guarantees that every error is handled properly to the point where data are accessible. If data is nil, the failure callback will be called
    func retrieveData<T>(failure: @escaping ((BackendError<T>) -> Void)) -> Success? where T: RequestError {

        if let error = self.retrieveBackendError(T.self) {
            failure(error)
            return nil
        }

        guard let data = self.value else {
            failure(BackendError<T>(networkLayerError: NetworkError.invalidResponse, backendError: nil))
            return nil
        }
        return data
    }
}

struct DictSerializer: ResponseSerializer {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [String: Any] {
        let json = try JSONResponseSerializer().serialize(request: request, response: response, data: data, error: error)
        if let dict = json as? [String: Any] {
            return dict
        }
        throw NetworkError.invalidResponsePayload
    }
}
