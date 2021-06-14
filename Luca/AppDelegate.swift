import UIKit
import IQKeyboardManagerSwift
import BackgroundTasks
import RxSwift

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        do {
            try ServiceContainer.shared.setup()
        } catch let error {
            log("Critical error: couldn't setup service container! \(error)", entryType: .error)
            fatalError()
        }

        // It enables intelligent text field behavior when the keyboard is covering the text field.
        IQKeyboardManager.shared.enable = true

        if #available(iOS 13, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "de.culture4life.matchTraces",
                                            using: nil) { (task) in
                guard let appRefreshTask = task as? BGAppRefreshTask else {
                    fatalError("Expected task to be of type BGAppRefreshTask")
                }
                self.handleAppRefresh(task: appRefreshTask)
            }
            BGTaskScheduler.shared.cancelAllTaskRequests()
        } else {
            // Fetch data once an hour
            UIApplication.shared.setMinimumBackgroundFetchInterval(3600)
        }

        #if DEBUG
        // Test BGTask using https://developer.apple.com/documentation/backgroundtasks/starting_and_terminating_tasks_during_development
        DispatchQueue.main.async { NotificationScheduler.shared.scheduleNotification(title: "App delegate", message: "for iOS 13+") }
        #endif

        ServiceContainer.shared.notificationService.removePendingNotificationsIfNotCheckedIn()

        return true
    }

    // Background fetch for iOS 12 and under
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if #available(iOS 13, *) { } else {
            do {
                try ServiceContainer.shared.setup()
            } catch let error {
                log("Critical error: couldn't setup service container! \(error)", entryType: .error)
                fatalError()
            }

            ServiceContainer.shared.accessedTracesChecker.sendNotificationOnMatch(completionHandler: completionHandler)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if #available(iOS 13, *) {
            scheduleAppRefresh()
        }
    }

    @available(iOS 13.0, *)
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        task.expirationHandler = {
            ServiceContainer.shared.accessedTracesChecker.disposeNotificationOnMatch()
            task.setTaskCompleted(success: false)
        }

        do {
            try ServiceContainer.shared.setup()
        } catch let error {
            log("Critical error: couldn't setup service container! \(error)", entryType: .error)
            fatalError()
        }

        ServiceContainer.shared.accessedTracesChecker.sendNotificationOnMatch(task: task)
    }

    @available(iOS 13.0, *)
    // TEST in debug console: e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"de.culture4life.matchTraces"]
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "de.culture4life.matchTraces")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            log("Could not schedule app refresh: \(error.localizedDescription)")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Pull keys when app enters foreground
        ServiceContainer.shared.baerCodeKeyService.setup()
        ServiceContainer.shared.notificationService.removePendingNotificationsIfNotCheckedIn()
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return false
        }

        if let selfCheckin = CheckInURLParser.parse(url: incomingURL) {
            ServiceContainer.shared.selfCheckin.add(selfCheckinPayload: selfCheckin)
        } else if incomingURL.absoluteString.hasPrefix(CoronaTestDeeplinkService.deeplinkTestPrefix) {

            // TODO: temporal solution, remove asap
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                CoronaTestDeeplinkService.postDeeplinkNotification(test: incomingURL.absoluteString)
            }
        }

        return true
    }

}

extension AppDelegate: UnsafeAddress, LogUtil {}

import UserNotifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
