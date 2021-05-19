import UIKit
import PhoneNumberKit
import DeviceKit
import RxSwift

fileprivate extension UIViewController {
    static func instantiate<T: UIViewController>(storyboard: UIStoryboard, identifier: String) -> T {
        let viewController = storyboard.instantiateViewController(withIdentifier: identifier) as? T
        if viewController == nil {
            print("Error instantiating UIViewController. Storyboard is setup incorrectly.")
        }
        // Is purposefully force unwrapped to crash the system if the storyboard is setup incorrectly.
        return viewController!
    }
}

class OnboardingViewControllerFactory {

    private static var storyboard = UIStoryboard(name: "Onboarding", bundle: nil)

    static func instantiateViewController<T: UIViewController>(identifier: String) -> T {
        UIViewController.instantiate(storyboard: storyboard, identifier: identifier)
    }

    static func createFormViewController() -> UIViewController {
        return storyboard.instantiateViewController(withIdentifier: "FormViewController")
    }

    static func createWelcomeViewController() -> UIViewController {
        return storyboard.instantiateViewController(withIdentifier: "WelcomeViewController")
    }

    static func createDataPrivacyViewController() -> UIViewController {
        return storyboard.instantiateViewController(withIdentifier: "DataPrivacyViewController")
    }

    static func createDoneViewController() -> UIViewController {
        return storyboard.instantiateViewController(withIdentifier: "DoneViewController")
    }

    static func createWebViewController(url: URL) -> WebViewController {
        let vc: WebViewController = instantiateViewController(identifier: "WebViewController")
        vc.url = url
        return vc
    }

}

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

    static func createTANReleaseViewController() -> TANReleaseViewController {
        return instantiateViewController(identifier: "TANReleaseViewController")
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

    static func createDataAccessConfirmationViewController(confirmAction: @escaping () -> Void) -> AlertWithLinkViewController {
        let alert: AlertWithLinkViewController = instantiateViewController(identifier: "AlertWithLinkViewController")
        alert.setup(withTitle: L10n.History.Alert.title,
                    description: L10n.History.Alert.description(L10n.History.Alert.link),
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

    static func createTestPrivacyConsent(confirmAction: @escaping () -> Void) -> AlertWithLinkViewController {
        let alert: AlertWithLinkViewController = instantiateViewController(identifier: "AlertWithLinkViewController")
        let link = L10n.History.Alert.link
        alert.setup(withTitle: L10n.Tests.Uniqueness.Consent.title,
                    description: L10n.Tests.Uniqueness.Consent.description(link),
                    link: link,
                    url: ServiceContainer.shared.backendAddressV3.privacyPolicyUrl,
                    confirmAction: confirmAction)
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

class MainViewControllerFactory {

    private static var storyboard = UIStoryboard(name: "Main", bundle: nil)

    static func instantiateViewController<T: UIViewController>(identifier: String) -> T {
        UIViewController.instantiate(storyboard: storyboard, identifier: identifier)
    }

    static func createTabBarController() -> MainTabBarViewController {
        return instantiateViewController(identifier: "MainTabBarController")
    }

    static func createLocationCheckinViewController(traceInfo: TraceInfo) -> LocationCheckinViewController {
        let viewController: LocationCheckinViewController = instantiateViewController(identifier: "LocationCheckinViewController")

        let sc = ServiceContainer.shared
        viewController.viewModel = DefaultLocationCheckInViewModel(
            traceInfo: traceInfo,
            traceIdService: sc.traceIdService,
            timer: CheckinTimer.shared,
            preferences: LucaPreferences.shared,
            locationUpdater: sc.locationUpdater,
            locationPermissionHandler: LocationPermissionHandler.shared,
            regionMonitor: sc.regionMonitor,
            notificationService: NotificationService.shared)

        return viewController
    }

    static func createContactViewController() -> ContactViewController {
        return instantiateViewController(identifier: "ContactViewController")
    }

    static func createDataAccessViewController() -> DataAccessViewController {
        return instantiateViewController(identifier: "DataAccessViewController")
    }

    static func createPrivateMeetingViewController(meeting: PrivateMeetingData) -> PrivateMeetingViewController {
        let vc: PrivateMeetingViewController = instantiateViewController(identifier: "PrivateMeetingViewController")
        vc.meeting = meeting
        return vc
    }

    static func createQRScannerViewController() -> QRScannerViewController {
        return instantiateViewController(identifier: "QRScannerViewController")
    }

    static func createTestQRScannerViewController() -> TestQRCodeScannerController {
        return instantiateViewController(identifier: "TestQRCodeScannerController")
    }

}
