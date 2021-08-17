import UIKit
import RxSwift

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

    static func actionAndCancelAlert(viewController: UIViewController, title: String, message: String, actionTitle: String, action: @escaping() -> Void, cancelAction: @escaping() -> Void) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
            action()
        })
        alert.addAction(UIAlertAction(title: L10n.Navigation.Basic.cancel, style: .cancel) { _ in
            cancelAction()
        })
        alert.view.tintColor = UIColor.lucaAlertTint
        return alert
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

    func menuActionSheet(viewController: UIViewController, additionalActions: [UIAlertAction] = []) {
        self.addAction(UIAlertAction(title: L10n.Navigation.Basic.cancel, style: .cancel, handler: nil))
        for action in additionalActions { self.addAction(action) }
        viewController.present(self, animated: true)
    }

    func termsAndConditionsActionSheet(viewController: UIViewController, additionalActions: [UIAlertAction] = []) {
        self.addAction(UIAlertAction(title: L10n.Terms.Acceptance.termsAndConditionsChanges, style: .default) { _ in
            guard let url = URL(string: L10n.Terms.Acceptance.linkChanges) else {
                return
            }
            UIApplication.shared.open(url, options: [:])
        })

        self.addAction(UIAlertAction(title: L10n.Navigation.Basic.cancel, style: .cancel, handler: nil))
        for action in additionalActions { self.addAction(action) }
        viewController.present(self, animated: true)
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
