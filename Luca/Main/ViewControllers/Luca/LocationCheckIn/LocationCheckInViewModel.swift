import Foundation
import RxSwift
import RxCocoa

struct PrintableError: Error {
    var error: Error?
    var title: String
    var message: String
}

protocol LocationCheckInViewModel {
    typealias PrintableMessage = (title: String, message: String)

    /// It emits every error and information that user should know of
    var alert: Driver<PrintableMessage> { get }

    /// It emits true when the app is busy and user is not allowed to interact with the UI
    var isBusy: Driver<Bool> { get }

    /// It emits true when the label and the toggle should be visible
    var isAutoCheckoutAvailable: Driver<Bool> { get }

    /// It emits current auto-checkout setting
    var isAutoCheckoutEnabled: BehaviorRelay<Bool> { get }

    /// Emits current check in status. If false, the view should be dismissed
    var isCheckedIn: Driver<Bool> { get }

    /// It contains location name that should be presented on the screen
    var locationName: Driver<String?> { get }

    /// It contains group name that should be presented on the screen
    var groupName: Driver<String?> { get }

    /// It emits time string every second
    var time: Driver<String> { get }

    /// Emits true when the label with additional data should be hidden
    var additionalDataLabelHidden: Driver<Bool> { get }

    /// Contents of the additional data label
    var additionalDataLabelText: Driver<String> { get }

    /// It emits constant check in time
    var checkInTime: Driver<String> { get }

    /// Emits the original checkin time
    var checkInTimeDate: Single<Date> { get }

    /// Triggers the checkout sequence. All errors are `PrintableError` and are localized ready to be printed in form of an alert controller
    /// - parameter viewController: auxilary view controller needed for some additional alert controllers
    func checkOut() -> Completable

    /// Should be called to perform clean up tasks upon dismiss
    func release()

    /// Should be called when all bindings are done and view is ready to perform
    func connect(viewController: UIViewController)
}
