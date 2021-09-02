import UIKit

public enum OnboardingStep: Int {

    case name = 0
    case phoneNumber = 1
    case address = 2

    var formComponents: [FormComponentType] {
        switch self {
        case .name: return [.firstName, .lastName]
        case .phoneNumber: return [.phoneNumber, .email]
        case .address: return [.street, .houseNumber, .postCode, .city]
        }
    }

    var requirements: [Bool] {
        switch self {
        case .name: return [true, true]
        case .phoneNumber: return [true, false]
        case .address: return [true, true, true, true]
        }
    }

    var formTitle: String {
        switch self {
        case .name: return L10n.UserData.Form.Name.formTitle
        case .phoneNumber: return L10n.UserData.Form.Phone.formTitle
        case .address: return L10n.UserData.Form.Address.formTitle
        }
    }

    var buttonTitle: String {
        switch self {
        case .name, .phoneNumber: return L10n.Navigation.Basic.next
        case .address: return L10n.Navigation.Basic.done
        }
    }

    var progress: Float {
        switch self {
        case .name: return 0.0
        case .phoneNumber: return 1.0/3.0
        case .address: return 2.0/3.0
        }
    }

    var additionalInfo: String? {
        switch self {
        case .name: return L10n.UserData.Name.mandatory
        case .phoneNumber: return L10n.UserData.Phone.mandatory
        case .address: return L10n.UserData.Address.mandatory
        }
    }

}
