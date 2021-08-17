import Foundation

public class UserRegistrationData: Codable {

    var firstName: String?
    var lastName: String?
    var street: String?
    var houseNumber: String?
    var postCode: String?
    var city: String?
    var phoneNumber: String?
    var email: String?

    init() {
    }

}

extension UserRegistrationData {
    var addressComplete: Bool {
        return !String.isNilOrEmpty(street) &&
            !String.isNilOrEmpty(houseNumber) &&
            !String.isNilOrEmpty(postCode) &&
            !String.isNilOrEmpty(city)
    }

    var personalDataComplete: Bool {
        return !String.isNilOrEmpty(firstName) &&
            !String.isNilOrEmpty(lastName) &&
            !String.isNilOrEmpty(phoneNumber)
    }

    var dataComplete: Bool {
        return addressComplete && personalDataComplete
    }
}

extension UserRegistrationData: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = UserRegistrationData()

        copy.firstName = firstName
        copy.lastName = lastName
        copy.street = street
        copy.houseNumber = houseNumber
        copy.postCode = postCode
        copy.city = city
        copy.phoneNumber = phoneNumber
        copy.email = email

        return copy
    }
}
