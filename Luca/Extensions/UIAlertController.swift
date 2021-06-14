import UIKit
import RxSwift
import DeviceKit
import LicensesViewController

extension UIAlertController {

    static func infoAlert(title: String, message: String, onOk: (() -> Void)? = nil) -> UIAlertController {
        let alert = CustomAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Navigation.Basic.ok, style: .default, handler: { _ in onOk?() }))
        alert.view.tintColor = UIColor.lucaAlertTint
        return alert
    }
    /// Alert controller without actions. It has to be dismissed in code. Used for blocking UI for some critical reasons
    static func infoBox(title: String, message: String) -> UIAlertController {
        let alert = CustomAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = UIColor.lucaAlertTint
        return alert
    }

    /// It presents an alert on subscribe and completes on "ok" button. Dismissed when disposed
    static func infoAlertRx(viewController: UIViewController, title: String, message: String) -> Observable<UIAlertController> {
        return Observable<UIAlertController>.create { observer in
            let alert = UIAlertController.infoAlert(title: title, message: message) {
                observer.onCompleted()
                // swiftlint:disable:next force_cast
            } as! CustomAlertController

            // This is in case someone dismisses the view controller outside of the stream. The stream should complete nevertheless.
            alert.onDismissBegin = {
                observer.onCompleted()
            }

            viewController.present(alert, animated: true, completion: nil)

            observer.onNext(alert)
            return Disposables.create {
                // Disable safety notification, this stream is being disposed.
                alert.onDismissBegin = nil
                alert.dismiss(animated: true, completion: nil)
            }
        }
        .subscribe(on: MainScheduler.instance)
    }

    static func noInternetError(onOk: (() -> Void)? = nil) -> UIAlertController {
        return infoAlert(title: L10n.Navigation.Basic.error, message: L10n.General.Failure.NoInternet.message, onOk: onOk)
    }

    /// It presents an alert on subscribe and emits the instance.
    /// - complete: when alert is dismissed
    /// - error: None
    /// - onDispose: dismisses the alert
    static func infoBoxRx(viewController: UIViewController, title: String, message: String) -> Observable<UIAlertController> {
        return Observable.create { observer in
            // swiftlint:disable:next force_cast
            let alert = CustomAlertController.infoBox(title: title, message: message) as! CustomAlertController

            // This is in case someone dismisses the view controller outside of the stream. The stream should complete nevertheless.
            alert.onDismissBegin = {
                observer.onCompleted()
            }

            viewController.present(alert, animated: true, completion: nil)
            observer.onNext(alert)
            return Disposables.create {
                // Disable safety notification, this stream is being disposed.
                alert.onDismissBegin = nil
                alert.dismiss(animated: true, completion: nil)
            }
        }
        .subscribe(on: MainScheduler.instance)
    }

    static func yesOrNo(title: String, message: String, onYes: (() -> Void)? = nil, onNo: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Navigation.Basic.yes, style: .default, handler: { _ in onYes?() }))
        alert.addAction(UIAlertAction(title: L10n.Navigation.Basic.no, style: .cancel, handler: { _ in onNo?() }))
        alert.view.tintColor = UIColor.lucaAlertTint
        return alert
    }

    static func okAndCancelAlertRx(viewController: UIViewController, title: String, message: String) -> Observable<(Bool)> {
        return Observable.create { observer in
            let alert = UIAlertController.okAndCancelAlert(title: title, message: message) { success in
                observer.onNext(success)
            }
            viewController.present(alert, animated: true, completion: nil)
            return Disposables.create {
                alert.dismiss(animated: true, completion: nil)
            }
        }
        .subscribe(on: MainScheduler.instance)
    }

    static func okAndCancelAlert(title: String, message: String, completed: @escaping(Bool) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Navigation.Basic.ok, style: .default, handler: { _ in completed(true) }))
        alert.addAction(UIAlertAction(title: L10n.Navigation.Basic.cancel, style: .cancel, handler: { _ in completed(false) }))
        alert.view.tintColor = UIColor.lucaAlertTint
        return alert
    }

    func yesActionAndNoAlert(action: @escaping() -> Void, viewController: UIViewController) {
        let action = UIAlertAction(title: L10n.Navigation.Basic.yes, style: .default) { _ in
            action()
        }

        let cancelAction = UIAlertAction(title: L10n.Navigation.Basic.no, style: .cancel)

        self.addAction(action)
        self.addAction(cancelAction)
        self.view.tintColor = UIColor.lucaAlertTint

        viewController.present(self, animated: true, completion: nil)
    }

    func actionAndCancelAlert(actionText: String, action: @escaping() -> Void, viewController: UIViewController) {
        let action = UIAlertAction(title: actionText, style: .default) { _ in
            action()
        }

        let cancelAction = UIAlertAction(title: L10n.Navigation.Basic.cancel, style: .cancel)

        self.addAction(action)
        self.addAction(cancelAction)
        self.view.tintColor = UIColor.lucaAlertTint

        viewController.present(self, animated: true, completion: nil)
    }

    func goToApplicationSettings(viewController: UIViewController, pop: Bool = false) {
        let okAction = UIAlertAction(title: L10n.Navigation.Basic.ok, style: .default) { _ in
            UIApplication.shared.openApplicationSettings()
            self.dismiss(animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: L10n.Navigation.Basic.cancel, style: .cancel) { _ in
            if pop {
                viewController.navigationController?.popViewController(animated: true)
            }
            self.dismiss(animated: true, completion: nil)
        }

        addAction(okAction)
        addAction(cancelAction)
        view.tintColor = UIColor.lucaAlertTint

        viewController.present(self, animated: true, completion: nil)
    }

    func dataPrivacyActionSheet(viewController: UIViewController, additionalActions: [UIAlertAction] = []) {
        self.addAction(UIAlertAction(title: L10n.General.dataPrivacy, style: .default) { _ in
            self.openDataPrivacyLink(viewController: viewController)
        })
        self.addAction(UIAlertAction(title: L10n.General.termsAndConditions, style: .default) { _ in
            self.openTermsAndConditionsLink(viewController: viewController)
        })
        self.addAction(UIAlertAction(title: L10n.General.imprint, style: .default) { _ in
            self.openImprintLink(viewController: viewController)
        })
        self.addAction(UIAlertAction(title: L10n.acknowledgements, style: .default) { _ in
            self.openLicenses(viewController: viewController)
        })
        self.addAction(UIAlertAction(title: L10n.General.faq, style: .default) { _ in
            self.openFAQLink(viewController: viewController)
        })

        self.addAction(UIAlertAction(title: L10n.Navigation.Basic.cancel, style: .cancel, handler: nil))
        for action in additionalActions { self.addAction(action) }
        viewController.present(self, animated: true)
    }

    func openLicenses(viewController: UIViewController) {
        let vc = LicensesViewController()
        vc.loadPlist(Bundle.main, resourceName: "Credits")
        viewController.navigationController?.pushViewController(vc, animated: true)
    }

    func menuActionSheet(viewController: UIViewController, additionalActions: [UIAlertAction] = []) {
        self.addAction(UIAlertAction(title: L10n.Navigation.Basic.cancel, style: .cancel, handler: nil))
        for action in additionalActions { self.addAction(action) }
        viewController.present(self, animated: true)
    }

    func openDataPrivacyLink(viewController: UIViewController) {
        guard let url = URL(string: L10n.WelcomeViewController.linkPrivacyPolicy) else {
            return
        }
        UIApplication.shared.open(url, options: [:])
    }

    func openTermsAndConditionsLink(viewController: UIViewController) {
        guard let url = URL(string: L10n.WelcomeViewController.linkTC) else {
            return
        }
        UIApplication.shared.open(url, options: [:])
    }

    func openFAQLink(viewController: UIViewController) {
        guard let url = URL(string: L10n.WelcomeViewController.linkFAQ) else {
            return
        }
        UIApplication.shared.open(url, options: [:])
    }

    func openImprintLink(viewController: UIViewController) {
        guard let url = URL(string: L10n.General.linkImprint) else {
            return
        }
        UIApplication.shared.open(url, options: [:])
    }
}

private class CustomAlertController: UIAlertController {
    public var onDismissBegin: (() -> Void)?
    public var onDismissEnd: (() -> Void)?

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.onDismissBegin?()
        super.dismiss(animated: true) {
            self.onDismissEnd?()
            completion?()
        }
    }
}
