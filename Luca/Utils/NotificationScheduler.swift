import Foundation
#if DEBUG
import UserNotifications
#endif

public class NotificationScheduler {

    public static let shared = NotificationScheduler()
    public static let runtimeId = Int.random(in: 0...100)

    public func scheduleNotification(title: String, message: String, date: Date? = nil, requestIdentifier: String? = nil, threadIdentifier: String? = nil) {

        #if DEBUG
        let content = UNMutableNotificationContent()

        content.title = title
        content.body = "\(message)\nRuntimeId: \(NotificationScheduler.runtimeId)"
        content.threadIdentifier = "Debug Notifications.\(threadIdentifier)"

        var trigger: UNNotificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        if let dateTrigger = date {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: dateTrigger.timeIntervalSince1970 - Date().timeIntervalSince1970, repeats: false)
        }
        let identifier = requestIdentifier ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
        #endif
    }
}
