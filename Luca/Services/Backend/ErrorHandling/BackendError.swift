import Foundation


struct BackendError<RequestErrorType>: LocalizedTitledError where RequestErrorType: RequestError {
    var networkLayerError: NetworkError? = nil
    var backendError: RequestErrorType? = nil
}

extension BackendError {
    var errorDescription: String? {
        if let network = networkLayerError {
            return network.errorDescription
        }
        if let backend = backendError {
            return backend.errorDescription
        }
        return L10n.General.Failure.Unknown.message("...")
    }
    var localizedTitle: String {
        if let network = networkLayerError {
            return network.localizedTitle
        }
        if let backend = backendError {
            return backend.localizedTitle
        }
        return L10n.Navigation.Basic.error
    }
}
