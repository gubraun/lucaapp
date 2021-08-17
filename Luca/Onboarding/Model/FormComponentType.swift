import UIKit
import Validator

public enum FormComponentType {

    case firstName
    case lastName
    case street
    case houseNumber
    case postCode
    case city
    case phoneNumber
    case email

    var placeholder: String {
        switch self {
        case .firstName:    return L10n.UserData.Form.firstName
        case .lastName:     return L10n.UserData.Form.lastName
        case .street:       return L10n.UserData.Form.street
        case .houseNumber:  return L10n.UserData.Form.houseNumber
        case .postCode:     return L10n.UserData.Form.postCode
        case .city:         return L10n.UserData.Form.city
        case .phoneNumber:  return L10n.UserData.Form.phoneNumber
        case .email:        return L10n.UserData.Form.email
        }
    }

    var value: String? {
        switch self {
        case .firstName:    return LucaPreferences.shared.firstName
        case .lastName:     return LucaPreferences.shared.lastName
        case .street:       return LucaPreferences.shared.street
        case .houseNumber:  return LucaPreferences.shared.houseNumber
        case .postCode:     return LucaPreferences.shared.postCode
        case .city:         return LucaPreferences.shared.city
        case .phoneNumber:  return LucaPreferences.shared.phoneNumber
        case .email:        return LucaPreferences.shared.emailAddress
        }
    }

    var keyboardType: UIKeyboardType {
        print("Keyboard type for: \(self)")
        switch self {
        case .phoneNumber:  return .phonePad
        case .postCode:     return .numberPad
        case .email:        return .emailAddress
        case .lastName,
             .firstName:    return .webSearch
        default:            return .webSearch
        }
    }

    var textContentType: UITextContentType {
        switch self {
        case .firstName:    return .givenName
        case .lastName:     return .familyName
        case .street:       return .streetAddressLine1
        case .houseNumber:  return .streetAddressLine2
        case .postCode:     return .postalCode
        case .city:         return .addressCity
        case .phoneNumber:  return .telephoneNumber
        case .email:        return .emailAddress
        }
    }

    var accessibilityError: String? {
        switch self {
        case .email:        return nil
        default:            return L10n.UserData.Form.Field.error
        }
    }

}
