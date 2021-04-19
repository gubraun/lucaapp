import Foundation

class DataResetService {

    static func resetAll() {
        ServiceContainer.shared.history.clearEntries()
        ServiceContainer.shared.traceIdService.disposeData(clearTraceHistory: true)
        ServiceContainer.shared.keyValueRepo.removeAll(completion: {}, failure: { _ in })
        ServiceContainer.shared.traceInfoRepo.removeAll(completion: {}, failure: {_ in})
        ServiceContainer.shared.locationRepo.removeAll(completion: {}, failure: {_ in})
        ServiceContainer.shared.healthDepartmentRepo.removeAll(completion: {}, failure: {_ in})
        ServiceContainer.shared.accessedTraceIdRepo.removeAll(completion: {}, failure: {_ in})
        Self.resetUserData()
        Self.resetOnboarding()
    }

    static func resetUserData() {
        LucaPreferences.shared.userRegistrationData = nil
        LucaPreferences.shared.uuid = nil
        ServiceContainer.shared.userKeysBundle.removeKeys()
        do {
            try KeyStorage.purge()
        } catch let error {
            print("Keys couldn't be purged: \(error)")
        }
    }

    static func resetOnboarding() {
        LucaPreferences.shared.welcomePresented = false
        LucaPreferences.shared.dataPrivacyPresented = false
        LucaPreferences.shared.currentOnboardingPage = 0
    }

    static func resetHistory() {
        ServiceContainer.shared.history.clearEntries()
    }

}
