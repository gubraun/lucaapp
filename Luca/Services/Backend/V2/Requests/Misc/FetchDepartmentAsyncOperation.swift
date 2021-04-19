import Foundation

enum FetchHealthDepartmentError: RequestError {
    case notFound
}

extension FetchHealthDepartmentError {
    var errorDescription: String? {
        return "\(self)"
    }
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class FetchDepartmentAsyncOperation: BackendAsyncDataOperation<KeyValueParameters, HealthDepartment, FetchHealthDepartmentError> {
    init(backendAddress: BackendAddress, departmentId: UUID) {
        let fullUrl = backendAddress.apiUrl
            .appendingPathComponent("healthDepartments")
            .appendingPathComponent(departmentId.uuidString.lowercased())

        super.init(url: fullUrl,
                   method: .get,
                   errorMappings: [404: .notFound])
    }
}
