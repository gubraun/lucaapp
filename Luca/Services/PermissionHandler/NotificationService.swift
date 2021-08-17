import Foundation
import RxSwift

/// Service for the checkout notification which triggers to remind you to checkout from the location.
public class NotificationService {

    private static let repeatingCheckoutNotification = "repeatingCheckoutNotification"
    private static let checkoutNotification = "checkoutNotification"
    private let notificationCenter = UNUserNotificationCenter.current()
    private let traceIdService: TraceIdService
    private let autoCheckoutService: AutoCheckoutService

    private var disposeBag: DisposeBag?

    init(traceIdService: TraceIdService, autoCheckoutService: AutoCheckoutService) {
        self.traceIdService = traceIdService
        self.autoCheckoutService = autoCheckoutService

        // Trigger delegate setting
        print(NotificationPermissionHandler.shared.currentPermission)
    }

    /// Enables automatic check out and check in events listening
    func enable() {
        guard disposeBag == nil else {
            return
        }

        let newDisposeBag = DisposeBag()
        Observable.merge(
                traceIdService.isCurrentlyCheckedIn.asObservable(),
                traceIdService.isCurrentlyCheckedInChanges
            )
            .distinctUntilChanged()
            .flatMapLatest { isCheckedIn in
                self.autoCheckoutService.isFeatureFullyWorking
                    .do(onNext: { autoCheckoutRunning in
                        if isCheckedIn && !autoCheckoutRunning {
                            self.addNotification()
                        } else {
                            self.removePendingNotifications()
                        }
                    })
            }
            .subscribe()
            .disposed(by: newDisposeBag)
        self.disposeBag = newDisposeBag
    }

    /// Disables automatic events listening
    func disable() {
        disposeBag = nil
    }

    func addNotification() {
        if !LucaPreferences.shared.checkoutNotificationScheduled {
            let content = UNMutableNotificationContent()
            content.title = L10n.Notification.Checkout.title
            content.body = L10n.Notification.Checkout.description
            content.sound = UNNotificationSound.default
            // Send notification every two hours.
            let repeatingTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 60 * 60, repeats: true)

            // Send notification after five minutes.
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 5, repeats: false)

            let repeatingNotificationRequest = UNNotificationRequest(identifier: Self.repeatingCheckoutNotification, content: content, trigger: repeatingTrigger)
            let notificationRequest = UNNotificationRequest(identifier: Self.checkoutNotification, content: content, trigger: trigger)

            notificationCenter.add(repeatingNotificationRequest)
            notificationCenter.add(notificationRequest)
            LucaPreferences.shared.checkoutNotificationScheduled = true
        }
    }

    func removePendingNotifications() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [Self.repeatingCheckoutNotification, Self.checkoutNotification]
        )
        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: [Self.repeatingCheckoutNotification, Self.checkoutNotification ]
        )
        LucaPreferences.shared.checkoutNotificationScheduled = false
    }

    func removePendingNotificationsIfNotCheckedIn() {
        _ = traceIdService.isCurrentlyCheckedIn
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { checkedIn in
                if !checkedIn { self.removePendingNotifications() }
            })
            .subscribe()
    }

}

extension NotificationService {
    func removePendingNotificationsRx() -> Completable {
        return Completable.from {
            self.removePendingNotifications()
        }
    }
}
