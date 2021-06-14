import Foundation

class DataResetService {

    static let log = GeneralPurposeLog(subsystem: "App", category: "DataResetService", subDomains: [])

    static func resetAll() {
        ServiceContainer.shared.traceIdService.disposeData(clearTraceHistory: true)

        for db in ServiceContainer.shared.realmDatabaseUtils {
            db.removeFile(completion: {}, failure: { _ in})
        }

        Self.resetUserData()
        Self.resetOnboarding()
    }

    static func resetUserData() {
        LucaPreferences.shared.userRegistrationData = nil
        LucaPreferences.shared.uuid = nil
        ServiceContainer.shared.userKeysBundle.removeKeys()
        ServiceContainer.shared.localDBKeyRepository.purge()
        do {
            try KeyStorage.purge()
        } catch let error {
            log.log("Keys couldn't be purged: \(error)", entryType: .error)
        }

        do {
            // It's needed to generate new local DB keys and to dispose old key references.
            try ServiceContainer.shared.setupRepos()
        } catch let error {
            log.log("Repos couldn't be re initialized: \(error)", entryType: .error)
        }
    }

    static func resetOnboarding() {
        LucaPreferences.shared.welcomePresented = false
        LucaPreferences.shared.dataPrivacyPresented = false
        LucaPreferences.shared.currentOnboardingPage = 0
        LucaPreferences.shared.phoneNumberVerified = false
        LucaPreferences.shared.verificationRequests = []
    }

    static func resetHistory() {
        ServiceContainer.shared.historyRepo.removeFile(completion: {}, failure: {_ in})
    }

}
