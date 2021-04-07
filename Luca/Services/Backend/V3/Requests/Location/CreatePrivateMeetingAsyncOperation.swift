import Foundation
import Security

enum CreatePrivateMeetingError: RequestError {
    case invalidKey
    case invalidInput
}

extension CreatePrivateMeetingError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class CreatePrivateMeetingAsyncOperation: BackendAsyncDataOperation<KeyValueParameters, PrivateMeetingIds, CreatePrivateMeetingError> {
    
    private var buildingError: CreatePrivateMeetingError? = nil
    
    init(backendAddress: BackendAddressV3, publicKey: SecKey) {
        
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("locations")
            .appendingPathComponent("private")
        
        var data = Data()
        do {
            data = try publicKey.toData()
        } catch {
            buildingError = CreatePrivateMeetingError.invalidKey
        }
        
        let parameters: [String: String] = ["publicKey": data.base64EncodedString()]
        
        super.init(url: fullUrl,
                   method: .post,
                   parameters: parameters,
                   errorMappings: [400: .invalidInput])
    }
    
    override func execute(completion: @escaping (PrivateMeetingIds) -> Void, failure: @escaping (BackendError<CreatePrivateMeetingError>) -> Void) -> (() -> Void) {
        
        if let error = buildingError {
            failure(BackendError(backendError: error))
            return {}
        }
        return super.execute(completion: completion, failure: failure)
    }
}
