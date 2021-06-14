import Foundation
import UIKit
import JGProgressHUD
import Alamofire

enum UserServiceError: LocalizedTitledError {
    case localDataIncomplete
    case unableToGenerateKeys(error: Error)
    case networkError(error: NetworkError)
    case dailyKeyRepoError(error: DailyKeyRepoHandlerError)
    case userRegistrationError(error: BackendError<CreateUserError>)
    case userTransferError(error: BackendError<UserTransferError>)
    case userUpdateError(error: BackendError<UpdateUserError>)
    case userDeletionError(error: BackendError<DeleteUserError>)
    case unknown(error: Error)
}

extension UserServiceError {
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return error.localizedDescription
        case .dailyKeyRepoError(let error):
            return error.localizedDescription
        case .userRegistrationError(let error):
            return error.localizedDescription
        case .userTransferError(let error):
            return error.localizedDescription
        case .userUpdateError(let error):
            return error.localizedDescription
        default:
            return "\(self)"
        }
    }

    var error: Error? {
        switch self {
        case .localDataIncomplete:
            return self
        case .unableToGenerateKeys(error: let error):
            return error
        case .networkError(let error):
            return error
        case .dailyKeyRepoError(error: let error):
            return error
        case .userRegistrationError(error: let error):
            return error.backendError
        case .userTransferError(error: let error):
            return error.backendError
        case .userUpdateError(error: let error):
            return error.backendError
        case .userDeletionError(error: let error):
            return error.backendError
        case .unknown(error: let error):
            return error
        }
    }

    var localizedTitle: String {
        switch self {
        case .networkError(let error):
            return error.localizedTitle
        case .dailyKeyRepoError(let error):
            return error.localizedTitle
        case .userRegistrationError(let error):
            return error.localizedTitle
        case .userTransferError(let error):
            return error.localizedTitle
        case .userUpdateError(let error):
            return error.localizedTitle
        default:
            return L10n.Navigation.Basic.error
        }
    }
}

class UserService {

    enum Result {
        case userExists
        case userRecreated
    }
    // MARK: - private properties
    private let preferences: LucaPreferences
    private let backend: BackendUserV3
    private let userKeysBundle: UserKeysBundle
    private let dailyKeyRepoHandler: DailyKeyRepoHandler

    // MARK: - events
    public let onUserRegistered = "UserService.onUserRegistered"
    public let onUserUpdated = "UserService.onUserUpdated"
    public let onUserDataTransfered = "UserService.onUserDataTransfered"
    public let onUserDataTransferedNumberOfDays = "UserService.onUserDataTransfered.numberOfDays"

    // MARK: - implementation
    init(preferences: LucaPreferences,
         backend: BackendUserV3,
         userKeysBundle: UserKeysBundle,
         dailyKeyRepoHandler: DailyKeyRepoHandler) {
        self.preferences = preferences
        self.backend = backend
        self.userKeysBundle = userKeysBundle
        self.dailyKeyRepoHandler = dailyKeyRepoHandler
    }

    var isDataComplete: Bool {
        guard let user = preferences.userRegistrationData else {
            return false
        }
        return user.dataComplete
    }

    var isPersonalDataComplete: Bool {
        guard let user = preferences.userRegistrationData else {
            return false
        }
        return user.personalDataComplete
    }

    func uploadCurrentData(completion: @escaping () -> Void, failure: @escaping (UserServiceError) -> Void) {
        guard let userData = preferences.userRegistrationData,
              userData.dataComplete else {
            log("Upload current data: local data incomplete", entryType: .error)
            failure(.localDataIncomplete)
            return
        }

        guard let userId = preferences.uuid else {
            log("Upload current data: no user id", entryType: .error)
            failure(.localDataIncomplete)
            return
        }
        backend.update(userId: userId, userData: userData)
            .execute {
                NotificationCenter.default.post(Notification(name: Notification.Name(self.onUserUpdated), object: self, userInfo: nil))
                completion()
            } failure: { error in
                self.log("Upload current data error: \(error)", entryType: .error)
                failure(.userUpdateError(error: error))
            }
    }

    func deleteUserData(completion: @escaping () -> Void, failure: @escaping (UserServiceError) -> Void) {
        guard let userId = preferences.uuid else {
            log("Delete user: no user id", entryType: .error)
            failure(.localDataIncomplete)
            return
        }
        backend.delete(userId: userId).execute {
            completion()
        } failure: { error in
            self.log("User data deletion error: \(error)", entryType: .error)
            failure(.userDeletionError(error: error))
        }
    }

    func transferUserData(forNumberOfDays numberOfDays: Int, completion: @escaping (String) -> Void, failure: @escaping (UserServiceError) -> Void) {
        guard let userId = preferences.uuid else {
            log("Upload current data: no user id", entryType: .error)
            failure(.localDataIncomplete)
            return
        }
        backend.userTransfer(userId: userId, numberOfDays: numberOfDays).execute { (challengeId) in
            NotificationCenter.default.post(Notification(name: Notification.Name(self.onUserDataTransfered), object: self, userInfo: [self.onUserDataTransferedNumberOfDays: numberOfDays]))
            completion(challengeId)
        } failure: { error in
            self.log("Transfer user data error: \(error)", entryType: .error)
            failure(.userTransferError(error: error))
        }
    }

    func registerIfNeeded(completion: @escaping (Result) -> Void, failure: @escaping (UserServiceError) -> Void) {

        if !isDataComplete {
            failure(.localDataIncomplete)
            return
        }

        guard let userData = preferences.userRegistrationData else {
            failure(.localDataIncomplete)
            return
        }

        guard let uuid = preferences.uuid else {
            registerUser(userData: userData, completion: { completion(.userRecreated) }, failure: failure)
            return
        }

        backend.userExists(userId: uuid)
            .execute {
                completion(.userExists)
            } failure: { (error) in

                if let backendError = error.backendError,
                   backendError == .notFound {
                    self.registerUser(userData: userData, completion: { completion(.userRecreated) }, failure: failure)
                } else if let networkError = error.networkLayerError {
                    failure(.networkError(error: networkError))
                } else {
                    failure(.unknown(error: error))
                }
            }
    }

    private func registerUser(userData: UserRegistrationData, completion: @escaping () -> Void, failure: @escaping (UserServiceError) -> Void) {
        self.log("Registering user: regenerating keys")

        do {
            try self.userKeysBundle.generateKeys(forceRefresh: true)
        } catch let error {
            log("Unable to generate keys: \(error)", entryType: .error)
            failure(.unableToGenerateKeys(error: error))
            return
        }
        self.log("Registering user: keys regenerated")

        // Delete all daily keys to make sure there are no leftovers from other backend.
        // It should solve the problem with keys mismatch when switching between production and staging
        dailyKeyRepoHandler.removeAll()
        dailyKeyRepoHandler.fetch {

            self.backend.create(userData: userData)
                .execute { (userId) in
                    self.preferences.uuid = userId
                    self.preferences.onboardingComplete = true
                    NotificationCenter.default.post(Notification(name: Notification.Name(self.onUserRegistered), object: self, userInfo: nil))
                    completion()
                } failure: { error in
                    self.log("Registering user failed: \(error)", entryType: .error)
                    failure(.userRegistrationError(error: error))
                }

        } failure: { (error) in
            self.log("Fetching daily key failed: \(error)", entryType: .error)
            failure(.dailyKeyRepoError(error: error))
        }
    }
}

extension UserService: LogUtil, UnsafeAddress {}
