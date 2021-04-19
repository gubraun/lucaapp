import Foundation
import RxSwift
import RxCocoa

/// Handler for the checkout notification which triggers to remind you to checkout from the location.
class NotificationPermissionHandler: PermissionHandler<UNAuthorizationStatus> {

    public static let shared = NotificationPermissionHandler()
    public static let onNotificationPermissionChanged = "onNotificationPermissionChanged"
    public static let onAutoCheckoutChanged = "onAutoCheckoutChanged"

    var _bufferedPermission: UNAuthorizationStatus = .notDetermined

    override var currentPermission: UNAuthorizationStatus {
        return _bufferedPermission
    }

    public var notificationSettings: Observable<UNAuthorizationStatus> {
        return Observable<UNAuthorizationStatus>.create { observer in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                observer.onNext(settings.authorizationStatus)
            }
            return Disposables.create()
        }
    }

    override var permissionChanges: Observable<UNAuthorizationStatus> {
        let backgroundChanges = UIApplication.shared.rx.applicationWillEnterForeground
            .flatMap { _ in return self.notificationSettings }

        let foregroundChanges = NotificationCenter.default.rx.notification(NSNotification.Name(Self.onNotificationPermissionChanged), object: self)
            .flatMap { _ in return self.notificationSettings }

        return Observable.merge(backgroundChanges, foregroundChanges)
            .distinctUntilChanged()
            .map { permission -> UNAuthorizationStatus in
            self.setPermissionValue(permission: permission)
            return permission
        }
    }

    func setPermissionValue(permission: UNAuthorizationStatus) {
        _bufferedPermission = permission
    }

    func onNotificationPermissionChanged() {
        NotificationCenter.default.post(Notification(name: Notification.Name(Self.onNotificationPermissionChanged), object: self, userInfo: nil))
    }

    func requestAuthorization(viewController: UIViewController) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { didAllow, _ in
            self.onNotificationPermissionChanged()

            if !didAllow {
                DispatchQueue.main.async {
                    UIAlertController(title: L10n.Notification.Permission.title,
                                      message: L10n.Notification.Permission.description,
                                      preferredStyle: .alert)
                        .goToApplicationSettings(viewController: viewController)
                }
            }
        }
    }

}

import UserNotifications
extension NotificationPermissionHandler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
