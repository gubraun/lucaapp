import Foundation

class UserRegistrationDataIntermediate: Codable {
    var firstName: String?
    var lastName: String?
    var street: String?
    var houseNumber: String?
    var postCode: String?
    var city: String?
    var phoneNumber: String?
    var email: String?
    var version = 2

    init(userRegistrationData: UserRegistrationData) {
        self.firstName = userRegistrationData.firstName
        self.lastName = userRegistrationData.lastName
        self.street = userRegistrationData.street
        self.houseNumber = userRegistrationData.houseNumber
        self.postCode = userRegistrationData.postCode
        self.city = userRegistrationData.city
        self.phoneNumber = userRegistrationData.phoneNumber
        self.email = userRegistrationData.email
    }

    private enum CodingKeys: String, CodingKey {
        case firstName = "fn"
        case lastName = "ln"
        case street = "st"
        case houseNumber = "hn"
        case postCode = "pc"
        case city = "c"
        case phoneNumber = "pn"
        case email = "e"
        case version = "v"
    }
}
