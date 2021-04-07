import Foundation
import Alamofire
import DeviceKit

#if DEBUG
import Mocker
#endif

typealias KeyValueParameters = [String: String]

/// Contains current app version. Eg `1.2.3`
fileprivate let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown version"

/// Contains current device. Eg `iPhone8` or `Simulator (iPhone8)`
fileprivate let deviceModel = "\(Device.current)"

/// Contains the version of the system. Eg `14.1`
fileprivate let sysVersion = UIDevice.current.systemVersion
#if DEBUG
fileprivate let mode = "Debug"
#else
fileprivate let mode = "Release"
#endif

#if DEBUG
// Set this value to non nil to override ALL request status codes. When nil no mocking will be enabled
var testedBackendError: Int? = nil
#endif

let userAgent = "luca/\(appVersion) \(mode) (iOS \(sysVersion);\(deviceModel))"

class LucaAlamofireSessionBuilder {
    
    static func build(cachePolicy: NSURLRequest.CachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy, disableCache: Bool = true) -> Session {
        
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
            evaluators:
                ["app.luca-app.de": PinnedCertificatesTrustEvaluator(),     // Alamofire does not support wildcards
                 "staging.luca-app.de": PinnedCertificatesTrustEvaluator()
                ])
        
        return Session(configuration: configuration, serverTrustManager: trustManager)
    }
}

class BackendAsyncDataOperation<ParametersType, Result, RequestErrorType>:
    AsyncDataOperation<BackendError<RequestErrorType>, Result> where Result: Decodable,
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

        session = LucaAlamofireSessionBuilder.build(cachePolicy: cachePolicy, disableCache: disableCache)
        
        self.url = url
        self.parameters = parameters
        self.method = method
        self.errorMappings = errorMappings
    }
    
    override func execute(completion: @escaping (Result) -> Void, failure: @escaping (BackendError<RequestErrorType>) -> Void) -> (() -> Void) {
        var request = session.request(url, method: method, parameters: parameters, encoder: JSONParameterEncoder(encoder: JSONEncoderUnescaped()), headers: ["User-Agent": userAgent])
        
        for errorMapping in errorMappings {
            request = request.map(code: errorMapping.key, to: errorMapping.value)
        }
        
        #if DEBUG
        // To mock AF requests for testing
        if let statusCode = testedBackendError {
            let mockedData = try! JSONEncoder().encode(parameters)
            let mock = Mock(url: url, dataType: .json, statusCode: statusCode, data: [Mock.HTTPMethod(rawValue: method.rawValue)!: mockedData])
            mock.register()
        }
        #endif
        
        let startedRequest = request
            .validate(statusCode: 200...299)
            .responseDecodable(of: Result.self, completionHandler: { (response) in
                
                let _ = self
                
                guard let data = response.retrieveData(failure: failure) else {
                    return
                }
                completion(data)
            })
        
        return { startedRequest.cancel() }
    }
}

class BackendAsyncOperation<ParametersType, RequestErrorType>:
    AsyncOperation<BackendError<RequestErrorType>> where ParametersType: Encodable,
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
        
        session = LucaAlamofireSessionBuilder.build(cachePolicy: cachePolicy, disableCache: disableCache)
        
        self.url = url
        self.parameters = parameters
        self.method = method
        self.errorMappings = errorMappings
    }
    
    override func execute(completion: @escaping () -> Void, failure: @escaping (BackendError<RequestErrorType>) -> Void) -> (() -> Void) {
        var request = session!.request(url, method: method, parameters: parameters, encoder: JSONParameterEncoder(encoder: JSONEncoderUnescaped()), headers: ["User-Agent": userAgent])
        
        for errorMapping in errorMappings {
            request = request.map(code: errorMapping.key, to: errorMapping.value)
        }
        
        #if DEBUG
        // To mock AF requests for testing
        if let statusCode = testedBackendError {
            let mockedData = try! JSONEncoder().encode(parameters)
            let mock = Mock(url: url, dataType: .json, statusCode: statusCode, data: [Mock.HTTPMethod(rawValue: method.rawValue)!: mockedData])
            mock.register()
        }
        #endif
        
        let startedRequest = request
            .validate(statusCode: 200...299)
            .response { (response) in
                
                let _ = self
                if let error = response.retrieveBackendError(RequestErrorType.self) {
                    failure(error)
                    return
                }
                
                completion()
            }
        
        return { startedRequest.cancel() }
    }
}

class MappedBackendAsyncDataOperation<ParametersType, Result, RequestErrorType>:
    AsyncDataOperation<BackendError<RequestErrorType>, Result> where ParametersType: Encodable,
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
        
        session = LucaAlamofireSessionBuilder.build(cachePolicy: cachePolicy, disableCache: disableCache)
        
        self.url = url
        self.parameters = parameters
        self.method = method
        self.errorMappings = errorMappings
    }
    
    override func execute(completion: @escaping (Result) -> Void, failure: @escaping (BackendError<RequestErrorType>) -> Void) -> (() -> Void) {
        var request = session.request(url, method: method, parameters: parameters, encoder: JSONParameterEncoder(encoder: JSONEncoderUnescaped()), headers: ["User-Agent": userAgent])
        
        for errorMapping in errorMappings {
            request = request.map(code: errorMapping.key, to: errorMapping.value)
        }
        
        #if DEBUG
        // To mock AF requests for testing
        if let statusCode = testedBackendError {
            let mockedData = try! JSONEncoder().encode(parameters)
            let mock = Mock(url: url, dataType: .json, statusCode: statusCode, data: [Mock.HTTPMethod(rawValue: method.rawValue)!: mockedData])
            mock.register()
        }
        #endif
        
        let startedRequest = request
            .validate(statusCode: 200...299)
            .responseDict { (response) in
                
                let _ = self
                
                guard let dict = response.retrieveData(failure: failure) else {
                    return
                }
                do {
                    completion(try self.map(dict: dict))
                }
                catch let error as NetworkError {
                    failure(BackendError<RequestErrorType>(networkLayerError: error, backendError: nil))
                }
                catch let error {
                    failure(BackendError<RequestErrorType>(networkLayerError: NetworkError.unknown(error: error), backendError: nil))
                }
            }
        
        return { startedRequest.cancel() }
    }
    
    func map(dict: [String: Any]) throws -> Result {
        throw NetworkError.invalidResponsePayload
    }
}
