import Foundation
import Alamofire
import DeviceKit

#if DEBUG
import Mocker
#endif

typealias KeyValueParameters = [String: String]

#if DEVELOPMENT
private let mode = "Debug"
#elseif PENTEST
private let mode = "Pentest"
#elseif QA
private let mode = "QA"
#else
private let mode = "Release"
#endif

#if DEBUG
// Set this value to non nil to override ALL request status codes. When nil no mocking will be enabled
var testedBackendError: Int?
#endif

/// Contains current app version. Eg `1.2.3`
private let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown version"

let userAgent = "luca/iOS \(appVersion)"

private let authorizationCredentials = "\(secrets.backendLogin):\(secrets.backendPassword)".data(using: .utf8)!.base64EncodedString()
let authorizationContent = "Basic \(authorizationCredentials)"

class LucaAlamofireSessionBuilder {

    static func build(pinnedCertificateHost: String, cachePolicy: NSURLRequest.CachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy, disableCache: Bool = true) -> Session {

        let configuration = URLSessionConfiguration.af.default

        // To mock AF requests for testing
        #if DEBUG
        if testedBackendError != nil {
            configuration.protocolClasses = [MockingURLProtocol.self] + (configuration.protocolClasses ?? [])
        }
        #endif

        configuration.requestCachePolicy = cachePolicy
        if disableCache {
            configuration.urlCache = nil
        }
        let trustManager = ServerTrustManager(
            evaluators: [ pinnedCertificateHost: PinnedCertificatesTrustEvaluator() ]
        )

        return Session(configuration: configuration, serverTrustManager: trustManager)
    }
}

class BackendAsyncDataOperation<ParametersType, Result, RequestErrorType>: AsyncDataOperation<BackendError<RequestErrorType>, Result> where Result: Decodable,
                                                                     ParametersType: Encodable,
                                                                     RequestErrorType: RequestError {
    private let url: URL
    private let parameters: ParametersType?
    private let method: HTTPMethod
    private let errorMappings: [Int: RequestErrorType]
    private var session: Session!

    init(url: URL,
         method: HTTPMethod,
         parameters: ParametersType? = nil,
         cachePolicy: NSURLRequest.CachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy,
         disableCache: Bool = true,
         errorMappings: [Int: RequestErrorType]) {

        session = LucaAlamofireSessionBuilder.build(
            pinnedCertificateHost: url.host ?? "",
            cachePolicy: cachePolicy,
            disableCache: disableCache
        )

        self.url = url
        self.parameters = parameters
        self.method = method
        self.errorMappings = errorMappings
    }

    override func execute(completion: @escaping (Result) -> Void, failure: @escaping (BackendError<RequestErrorType>) -> Void) -> (() -> Void) {
        var request = session.request(
            url,
            method: method,
            parameters: parameters,
            encoder: JSONParameterEncoder(encoder: JSONEncoderUnescaped()),
            headers: ["User-Agent": userAgent,
                      "Authorization": authorizationContent])

        for errorMapping in errorMappings {
            request = request.map(code: errorMapping.key, to: errorMapping.value)
        }

        #if DEBUG
        // To mock AF requests for testing
        if let statusCode = testedBackendError {
            // swiftlint:disable:next force_try
            let mockedData = try! JSONEncoder().encode(parameters)
            let mock = Mock(url: url, dataType: .json, statusCode: statusCode, data: [Mock.HTTPMethod(rawValue: method.rawValue)!: mockedData])
            mock.register()
        }
        #endif

        let startedRequest = request
            .validate(statusCode: 200...299)
            .responseDecodable(of: Result.self, completionHandler: { (response) in

                _ = self

                guard let data = response.retrieveData(failure: failure) else {
                    return
                }
                completion(data)
            })

        return { startedRequest.cancel() }
    }
}

class BackendAsyncOperation<ParametersType, RequestErrorType>: AsyncOperation<BackendError<RequestErrorType>> where ParametersType: Encodable,
                                                         RequestErrorType: RequestError {
    private let url: URL
    private let parameters: ParametersType?
    private let method: HTTPMethod
    private let errorMappings: [Int: RequestErrorType]
    private var session: Session!

    init(url: URL,
         method: HTTPMethod,
         parameters: ParametersType? = nil,
         cachePolicy: NSURLRequest.CachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy,
         disableCache: Bool = true,
         errorMappings: [Int: RequestErrorType]) {

        session = LucaAlamofireSessionBuilder.build(
            pinnedCertificateHost: url.host ?? "",
            cachePolicy: cachePolicy,
            disableCache: disableCache
        )

        self.url = url
        self.parameters = parameters
        self.method = method
        self.errorMappings = errorMappings
    }

    override func execute(completion: @escaping () -> Void, failure: @escaping (BackendError<RequestErrorType>) -> Void) -> (() -> Void) {
        var request = session!.request(
            url,
            method: method,
            parameters: parameters,
            encoder: JSONParameterEncoder(encoder: JSONEncoderUnescaped()),
            headers: ["User-Agent": userAgent,
                      "Authorization": authorizationContent])

        for errorMapping in errorMappings {
            request = request.map(code: errorMapping.key, to: errorMapping.value)
        }

        #if DEBUG
        // To mock AF requests for testing
        if let statusCode = testedBackendError {
            // swiftlint:disable:next force_try
            let mockedData = try! JSONEncoder().encode(parameters)
            let mock = Mock(url: url, dataType: .json, statusCode: statusCode, data: [Mock.HTTPMethod(rawValue: method.rawValue)!: mockedData])
            mock.register()
        }
        #endif

        let startedRequest = request
            .validate(statusCode: 200...299)
            .response { (response) in

                _ = self
                if let error = response.retrieveBackendError(RequestErrorType.self) {
                    failure(error)
                    return
                }

                completion()
            }

        return { startedRequest.cancel() }
    }
}

class MappedBackendAsyncDataOperation<ParametersType, Result, RequestErrorType>: AsyncDataOperation<BackendError<RequestErrorType>, Result> where ParametersType: Encodable,
                                                                     RequestErrorType: RequestError {
    private let url: URL
    private let parameters: ParametersType?
    private let method: HTTPMethod
    private let errorMappings: [Int: RequestErrorType]
    private var session: Session!

    init(url: URL,
         method: HTTPMethod,
         parameters: ParametersType? = nil,
         cachePolicy: NSURLRequest.CachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy,
         disableCache: Bool = true,
         errorMappings: [Int: RequestErrorType]) {

        session = LucaAlamofireSessionBuilder.build(
            pinnedCertificateHost: url.host ?? "",
            cachePolicy: cachePolicy,
            disableCache: disableCache
        )

        self.url = url
        self.parameters = parameters
        self.method = method
        self.errorMappings = errorMappings
    }

    override func execute(completion: @escaping (Result) -> Void, failure: @escaping (BackendError<RequestErrorType>) -> Void) -> (() -> Void) {
        var request = session.request(
            url,
            method: method,
            parameters: parameters,
            encoder: JSONParameterEncoder(encoder: JSONEncoderUnescaped()),
            headers: ["User-Agent": userAgent,
                      "Authorization": authorizationContent])

        for errorMapping in errorMappings {
            request = request.map(code: errorMapping.key, to: errorMapping.value)
        }

        #if DEBUG
        // To mock AF requests for testing
        if let statusCode = testedBackendError {

            // swiftlint:disable:next force_try
            let mockedData = try! JSONEncoder().encode(parameters)
            let mock = Mock(url: url, dataType: .json, statusCode: statusCode, data: [Mock.HTTPMethod(rawValue: method.rawValue)!: mockedData])
            mock.register()
        }
        #endif

        let startedRequest = request
            .validate(statusCode: 200...299)
            .responseDict { (response) in

                _ = self

                guard let dict = response.retrieveData(failure: failure) else {
                    return
                }
                do {
                    completion(try self.map(dict: dict))
                } catch let error as NetworkError {
                    failure(BackendError<RequestErrorType>(networkLayerError: error, backendError: nil))
                } catch let error {
                    failure(BackendError<RequestErrorType>(networkLayerError: NetworkError.unknown(error: error), backendError: nil))
                }
            }

        return { startedRequest.cancel() }
    }

    func map(dict: [String: Any]) throws -> Result {
        throw NetworkError.invalidResponsePayload
    }
}
