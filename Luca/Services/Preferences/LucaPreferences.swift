import Foundation
import RxSwift

class LucaPreferences {
    
    static let shared = LucaPreferences()
    
    private let preferences: UserDataPreferences
    
    init() {
        preferences = UserDataPreferences(suiteName: "LucaPreferences")
    }
    
    var currentOnboardingPage: Int? {
        get {
            preferences.retrieve(key: "currentOnboardingPage")
        }
        set {
            preferences.store(newValue!, key: "currentOnboardingPage")
        }
    }
    
    var userRegistrationData: UserRegistrationData? {
        get {
            preferences.retrieve(key: "userRegistrationData", type: UserRegistrationData.self)
        }
        set {
            if let value = newValue {
                preferences.store(value, key: "userRegistrationData")
            } else {
                preferences.remove(key: "userRegistrationData")
            }
        }
    }
    
    var firstName: String? {
        get {
            self.userRegistrationData?.firstName
        }
        set {
            let data = self.userRegistrationData
            data?.firstName = newValue
            self.userRegistrationData = data
        }
    }
    
    var lastName: String? {
        get {
            self.userRegistrationData?.lastName
        }
        set {
            let data = self.userRegistrationData
            data?.lastName = newValue
            self.userRegistrationData = data
        }
    }
    
    var street: String? {
        get {
            self.userRegistrationData?.street
        }
        set {
            let data = self.userRegistrationData
            data?.street = newValue
            self.userRegistrationData = data
        }
    }
    
    var houseNumber: String? {
        get {
            self.userRegistrationData?.houseNumber
        }
        set {
            let data = self.userRegistrationData
            data?.houseNumber = newValue
            self.userRegistrationData = data
        }
    }
    
    var postCode: String? {
        get {
            self.userRegistrationData?.postCode
        }
        set {
            let data = self.userRegistrationData
            data?.postCode = newValue
            self.userRegistrationData = data
        }
    }
    
    var city: String? {
        get {
            self.userRegistrationData?.city
        }
        set {
            let data = self.userRegistrationData
            data?.city = newValue
            self.userRegistrationData = data
        }
    }
    
    var phoneNumber: String? {
        get {
            self.userRegistrationData?.phoneNumber
        }
        set {
            let data = self.userRegistrationData
            data?.phoneNumber = newValue
            self.userRegistrationData = data
        }
    }
    
    var emailAddress: String? {
        get {
            self.userRegistrationData?.email
        }
        set {
            let data = self.userRegistrationData
            data?.email = newValue
            self.userRegistrationData = data
        }
    }
    
    var uuid: UUID? {
        get {
            preferences.retrieve(key: "uuid")
        }
        set {
            // Need to unwrap otherwise the store function for Data is used.
            if let value = newValue {
                preferences.store(value, key: "uuid")
            } else {
                preferences.remove(key: "uuid")
            }
            uuidPublisher.onNext(newValue)
        }
    }
    private var uuidPublisher = PublishSubject<UUID?>()
    
    /// Emits current value on subscribe and every subsequent changes
    public var uuidChanges: Observable<UUID?> {
        let current = Single.from { self.uuid }
        return Observable.merge(current.asObservable(), uuidPublisher)
    }
    
    var onboardingComplete: Bool {
        get {
            preferences.retrieve(key: "onboardingComplete") ?? false
        }
        set {
            preferences.store(newValue, key: "onboardingComplete")
        }
    }
    
    var welcomePresented: Bool {
        get {
            preferences.retrieve(key: "welcomePresented") ?? false
        }
        set {
            preferences.store(newValue, key: "welcomePresented")
        }
    }
    
    var donePresented: Bool {
        get {
            preferences.retrieve(key: "donePresented") ?? false
        }
        set {
            preferences.store(newValue, key: "donePresented")
        }
    }
    
    var dataPrivacyPresented: Bool {
        get {
            preferences.retrieve(key: "dataPrivacyPresented") ?? false
        } set {
            preferences.store(newValue, key: "dataPrivacyPresented")
        }
    }
    
    var phoneNumberVerified: Bool {
        get {
            preferences.retrieve(key: "phoneNumberVerified") ?? false
        }
        set {
            preferences.store(newValue, key: "phoneNumberVerified")
        }
    }
    
    var autoCheckout: Bool {
        get {
            preferences.retrieve(key: "autoCheckout") ?? false
        }
        set {
            preferences.store(newValue, key: "autoCheckout")
        }
    }
    
    var verificationRequests: [PhoneNumberVerificationRequest] {
        get {
            preferences.retrieve(key: "phoneVerificationRequest", type: [PhoneNumberVerificationRequest].self) ?? []
        }
        set {
            preferences.store(newValue, key: "phoneVerificationRequest")
        }
    }
    
    var checkoutNotificationScheduled: Bool {
        get {
            preferences.retrieve(key: "checkoutNotificationScheduled") ?? false
        }
        set {
            preferences.store(newValue, key: "checkoutNotificationScheduled")
        }
    }
    
}
