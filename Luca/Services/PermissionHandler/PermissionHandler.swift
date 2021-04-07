import Foundation
import RxSwift

enum PermissionHandlerError: Error {
    
    case unknown
    
    /// In case a state has been requested, that is not available. Example: CLAuthorizationState.notGranted cannot be requested.
    case invalidRequest
    
    /// Used in case where a permission request has been issued when user already saw a popup
    case cannotBeRequestedAnymore
}

protocol PermissionHandlerProtocol {
    associatedtype State
    
    var currentPermission: State { get }
    
    var permissionChanges: Observable<State> { get }
    
    func request(_ permission: State) -> Completable
}

class PermissionHandler<State>: NSObject, PermissionHandlerProtocol {
    var currentPermission: State {
        fatalError("Not implemented")
    }
    
    var permissionChanges: Observable<State> {
        fatalError("Not implemented")
    }
    
    func request(_ permission: State) -> Completable {
        fatalError("Not implemented")
    }
}
