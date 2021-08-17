import UIKit
import DeviceKit
import PhoneNumberKit
import RxSwift

class AlertViewControllerFactory {

    private static var storyboardLarge = UIStoryboard(name: "Alerts", bundle: nil)
    private static var storyboardSE = UIStoryboard(name: "AlertsSE", bundle: nil)

    private static let storyboardSEModels = [Device.iPhone5, Device.iPhone5c, Device.iPhone5s, Device.iPhoneSE]
    private static let storyboardSESimulators = [Device.simulator(.iPhone5), Device.simulator(.iPhone5c), Device.simulator(.iPhone5s), Device.simulator(.iPhoneSE)]

    private static var storyboard: UIStoryboard = {
        return storyboardSEModels.contains(Device.current) || storyboardSESimulators.contains(Device.current) ? storyboardSE : storyboardLarge
    }()

    static func instantiateViewController<T: UIViewController>(identifier: String) -> T {
        UIViewController.instantiate(storyboard: storyboard, identifier: identifier)
    }

    static func createPhoneNumberConfirmationViewController(phoneNumber: PhoneNumber) -> PhoneNumberConfirmationViewController {
        let vc: PhoneNumberConfirmationViewController = instantiateViewController(identifier: "PhoneNumberConfirmationViewController")
        vc.phoneNumber = phoneNumber
        return vc
    }

    static func createPhoneNumberVerificationViewController(challengeIDs: [String]) -> PhoneNumberVerificationViewController {
        let vc: PhoneNumberVerificationViewController = instantiateViewController(identifier: "PhoneNumberVerificationViewController")
        vc.challengeIds = challengeIDs
        return vc
    }

    static func createDataAccessAlertViewController(accesses: [HealthDepartment: [(TraceInfo, Location)]], allAccessesPressed: @escaping () -> Void) -> DataAccessAlertViewController {
        let vc: DataAccessAlertViewController = instantiateViewController(identifier: "DataAccessAlertViewController")
        vc.newDataAccesses = accesses
        vc.allAccessesPressed = allAccessesPressed
        return vc
    }

    static func createInfoViewController(titleText: String, descriptionText: String) -> InfoViewController {
        let viewController: InfoViewController = instantiateViewController(identifier: "InfoViewController")
        viewController.titleText = titleText
        viewController.descriptionText = descriptionText
        return viewController
    }

    static func createTANReleaseViewController(withNumberOfDaysTransferred numberOfDays: Int) -> TANReleaseViewController {
        let viewController: TANReleaseViewController = instantiateViewController(identifier: "TANReleaseViewController")
        viewController.numberOfTransferredDays = numberOfDays
        return viewController
    }

    static func createPrivateMeetingInfoViewController(historyEvent: HistoryEvent) -> PrivateMeetingInfoViewController {
        let viewController: PrivateMeetingInfoViewController = instantiateViewController(identifier: "PrivateMeetingInfoViewController")
        viewController.historyEvent = historyEvent
        return viewController
    }

    static func createAlertViewController(title: String, message: String, firstButtonTitle: String, firstButtonAction: (() -> Void)? = nil) -> LucaAlertViewController {
        let alert: LucaAlertViewController = instantiateViewController(identifier: "LucaAlertViewController")

        // Trigger loading
        _ = alert.view

        alert.titleLabel.text = title
        alert.messageLabel.text = message
        alert.firstButton.setTitle(firstButtonTitle, for: .normal)
        alert.onFirstButtonAction = firstButtonAction

        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overCurrentContext

        return alert
    }

    static func createDataAccessPickDaysViewController(confirmAction: @escaping (Int) -> Void) -> ShareHistoryPickDaysAlertViewController {
        let alert: ShareHistoryPickDaysAlertViewController = instantiateViewController(identifier: "ShareHistoryPickDaysAlertViewController")
        alert.setup(confirmAction: confirmAction)
        return alert
    }

    static func createDataAccessConfirmationViewController(numberOfDays: Int, confirmAction: @escaping () -> Void) -> AlertWithLinkViewController {
        let alert: AlertWithLinkViewController = instantiateViewController(identifier: "AlertWithLinkViewController")
        alert.setup(withTitle: L10n.History.Alert.title,
                    description: L10n.History.Alert.description(numberOfDays, L10n.History.Alert.link),
                    accessibility: L10n.History.Alert.Description.accessibility(L10n.History.Alert.link),
                    link: L10n.History.Alert.link,
                    url: ServiceContainer.shared.backendAddressV3.privacyPolicyUrl,
                    confirmAction: confirmAction)
        alert.view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        return alert
    }

    static func createLocationAccessInformationViewController(presentedOn viewController: UIViewController) -> Observable<AlertWithLinkViewController> {
        return Observable<AlertWithLinkViewController>.create { observer in
            let alert: AlertWithLinkViewController = instantiateViewController(identifier: "AlertWithLinkViewController")
            let link = L10n.LocationCheckinViewController.AutoCheckout.Permission.BeforePrompt.link
            alert.setup(withTitle: L10n.LocationCheckinViewController.AutoCheckout.Permission.BeforePrompt.title,
                        description: L10n.LocationCheckinViewController.AutoCheckout.Permission.BeforePrompt.message(link),
                        link: link,
                        url: ServiceContainer.shared.backendAddressV3.privacyPolicyUrl,
                        hasCancelButton: false,
                        continueButtonTitle: L10n.LocationCheckinViewController.AutoCheckout.Permission.BeforePrompt.okButton) {
                            observer.onCompleted()
                        }

            viewController.present(alert, animated: true, completion: nil)

            observer.onNext(alert)
            return Disposables.create {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }

    static func createTestPrivacyConsent(confirmAction: @escaping () -> Void, cancelAction: (() -> Void)? = nil) -> AlertWithLinkViewController {
        let alert: AlertWithLinkViewController = instantiateViewController(identifier: "AlertWithLinkViewController")
        let link = L10n.History.Alert.link
        alert.setup(withTitle: L10n.Tests.Uniqueness.Consent.title,
                    description: L10n.Tests.Uniqueness.Consent.description(link),
                    accessibilityTitle: L10n.Tests.Uniqueness.Consent.Title.accessibility,
                    link: link,
                    url: ServiceContainer.shared.backendAddressV3.privacyPolicyUrl,
                    continueButtonTitle: L10n.Navigation.Basic.yes.uppercased(),
                    confirmAction: confirmAction,
                    cancelAction: cancelAction)
        alert.view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        return alert
    }
}

extension AlertViewControllerFactory {
    static func createAlertViewControllerRx(
        presentingViewController viewController: UIViewController,
        title: String,
        message: String,
        firstButtonTitle: String) -> Observable<LucaAlertViewController> {

        return Observable<LucaAlertViewController>.create { observer in
            let alert = AlertViewControllerFactory.createAlertViewController(
                title: title,
                message: message,
                firstButtonTitle: firstButtonTitle) {
                observer.onCompleted()
            }

            // This is in case someone dismisses the view controller outside of the stream. The stream should complete nevertheless.
            alert.__onDidDisappear = {
                observer.onCompleted()
            }

            viewController.present(alert, animated: true, completion: nil)

            observer.onNext(alert)
            return Disposables.create {
                // Disable safety notification, this stream is being disposed.
                alert.__onDidDisappear = nil
                alert.dismiss(animated: true, completion: nil)
            }
        }
        .subscribe(on: MainScheduler.instance)
    }
}
