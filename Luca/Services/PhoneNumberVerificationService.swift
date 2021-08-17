import Foundation
import UIKit
import PhoneNumberKit
import RxSwift

struct PhoneNumberVerificationRequest: Codable {
    var challengeId: String
    var date: Date
    var phoneNumber: String
    var verified: Bool = false
}

public class PhoneNumberVerificationService {

    private let parentViewController: UIViewController
    private let backend: BackendSMSVerificationV3
    private let preferences: LucaPreferences

    private let phoneNumberKit = PhoneNumberKit()

    private let timeoutBase = 30.0

    init(presenting viewController: UIViewController,
         backend: BackendSMSVerificationV3,
         preferences: LucaPreferences) {

        self.parentViewController = viewController
        self.preferences = preferences
        self.backend = backend
    }

    /*
     1. Check if there is no timer and show it if so
     2. show the confirmation screen
     3. show the TAN input screen
     */
    var disposeBag = DisposeBag()
    func verify(phoneNumber: String, completion: @escaping (Bool) -> Void) {

        // QA Builds have no phone verification. From now on, anything will be accepted as a valid phone number.
        #if QA
        self.preferences.phoneNumberVerified = true
        completion(true)
        return
        #endif

        let requestNewTan = parseNumber(phoneNumber).ifEmpty(switchTo: Maybe.from { completion(false); return nil })
            .asObservable()
            .flatMap { parsedNumber -> Single<PhoneNumber>  in
                self.confirmPhoneNumber(phoneNumber: parsedNumber)
            }
            .flatMap { self.requestNewTAN(parsedNumber: $0).ifEmpty(switchTo: Maybe.from { completion(false); return nil }) }

        handleRequestDelay()
            .asObservable()
            .flatMap { timeoutActive -> Observable<String> in
                if !timeoutActive {
                    return requestNewTan
                }
                return Observable.just("")
            }
            .flatMap { _ in self.retrieveOpenChallenges() }
            .flatMap { challenges -> Completable in
                self.handlePhoneNumberVC(challenges: challenges)
                    .observe(on: MainScheduler.instance)
                    .do(onCompleted: { self.preferences.phoneNumberVerified = true; completion(true) })
            }
            .observe(on: MainScheduler.instance)
            .do(onError: { _ in completion(false) })
            .debug("verify sms")
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func retrieveOpenChallenges() -> Single<[String]> {
        Single.from {
            let refDate = Date().addingTimeInterval(-24 * 60 * 60)
            let retVal = self.preferences.verificationRequests
                .filter { !$0.verified }
                .filter { $0.date > refDate }
                .sorted { $0.date > $1.date }
                .prefix(10)

            return retVal.map { $0.challengeId }
        }
    }
    /// Emits the challenge that has been verified
    private func handlePhoneNumberVC(challenges: [String]) -> Completable {
        Completable.create { (observer) -> Disposable in

            let phoneNumberVC = ViewControllerFactory.Alert.createPhoneNumberVerificationViewController(challengeIDs: challenges)
            phoneNumberVC.modalTransitionStyle = .crossDissolve
            phoneNumberVC.modalPresentationStyle = .overCurrentContext
            phoneNumberVC.onSuccess = { challenge in
                DispatchQueue.main.async {
                    var requests = self.preferences.verificationRequests
                    if var request = requests.first(where: { $0.challengeId == challenge }) {
                        request.verified = true
                        requests.removeAll(where: { $0.challengeId == challenge })
                        requests.append(request)
                        requests.sort { $0.date > $1.date }
                        self.preferences.verificationRequests = requests
                    }
                }
                observer(.completed)
            }
            phoneNumberVC.onUserCanceled = { observer(.error(NSError(domain: "Phone number unverified", code: 0, userInfo: nil))) }
            self.parentViewController.present(phoneNumberVC, animated: true, completion: nil)

            return Disposables.create {
                phoneNumberVC.dismiss(animated: true, completion: nil)
            }
        }
        .subscribe(on: MainScheduler.instance)
    }

    func confirmPhoneNumber(phoneNumber: PhoneNumber) -> Single<PhoneNumber> {
        Single.create { observer -> Disposable in
            let viewController = ViewControllerFactory.Alert.createPhoneNumberConfirmationViewController(phoneNumber: phoneNumber)
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overFullScreen
            viewController.onSuccess = { observer(.success(phoneNumber)) }
            viewController.onCancel = { observer(.failure(NSError(domain: "Phone number unconfirmed", code: 0, userInfo: nil))) }
            self.parentViewController.present(viewController, animated: true, completion: nil)
            return Disposables.create {
                viewController.dismiss(animated: true, completion: nil)
            }
        }
    }

    private func parseNumber(_ number: String) -> Maybe<PhoneNumber> {
        Maybe.from {
            let parsedNumber = try self.phoneNumberKit.parse(number)
            return parsedNumber
        }
        .catch { _ in
            return self.wrongFormatAlert().andThen(Maybe.empty())
        }
    }

    private func wrongFormatAlert() -> Completable {
        ViewControllerFactory.Alert.createAlertViewControllerRx(
            presentingViewController: parentViewController,
            title: L10n.Navigation.Basic.error,
            message: L10n.Verification.PhoneNumber.wrongFormat,
            firstButtonTitle: L10n.Navigation.Basic.ok.uppercased())
            .ignoreElementsAsCompletable()
    }

    /// Emits `true` if timeout is active
    private func handleRequestDelay() -> Single<Bool> {
        Single.from {
            self.preferences.verificationRequests
        }
        .flatMap { _ in

            // If there is next allowed timestamp and it is in future, show the timer
            if let nextAllowedTimestamp = self.getNextAllowedRequestTimestamp(),
               Date().timeIntervalSince1970 < nextAllowedTimestamp {
                return ViewControllerFactory.Alert.createAlertViewControllerRx(
                    presentingViewController: self.parentViewController,
                    title: L10n.Verification.PhoneNumber.TimerDelay.title,
                    message: "",
                    firstButtonTitle: L10n.Navigation.Basic.ok.uppercased())
                    .materialize()
                    .flatMapLatest { event -> Single<Void> in
                        if let alert = event.element {
                            return Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
                                .take(until: { _ in Date().timeIntervalSince1970 >= nextAllowedTimestamp }, behavior: .inclusive)
                                .do(onNext: { _ in
                                    let totalSeconds = Int(abs(nextAllowedTimestamp - Date().timeIntervalSince1970))
                                    let minutes = totalSeconds / 60
                                    let seconds = totalSeconds - (minutes * 60)
                                    alert.message = L10n.Verification.PhoneNumber.TimerDelay.message(String(format: "%02i:%02i", minutes, seconds))
                                    alert.messageLabel.accessibilityLabel = L10n.Verification.PhoneNumber.TimerDelay.Message.accessibility(minutes, seconds)
                                })
                                .ignoreElementsAsCompletable()
                                .andThen(Single.just(Void()))
                        } else if let error = event.error {
                            throw error // Just push back any errors
                        }
                        return Single.just(Void())
                    }
                    .take(1)
                    .ignoreElementsAsCompletable()
                    .andThen(Single.from { Date().timeIntervalSince1970 < nextAllowedTimestamp })
            }
            // Just complete if there is no timestamp or it is in the past already
            return Single.just(false)
        }
    }

    /// Requests new TAN and emits a challenge if everything went well. It handles all internal errors by itself, so it won't emit any errors.
    private func requestNewTAN(parsedNumber: PhoneNumber) -> Maybe<String> {
        let formattedNumber = phoneNumberKit.format(parsedNumber, toType: .e164)
        return backend.requestChallenge(phoneNumber: formattedNumber)
            .asSingle()
            .debug("Challenge request info")
            .map { $0.challenge }
            .asMaybe()
            .do(onNext: { challenge in
                var requests = self.preferences.verificationRequests
                requests.append(PhoneNumberVerificationRequest(
                                    challengeId: challenge,
                                    date: Date(),
                                    phoneNumber: formattedNumber))
                self.preferences.verificationRequests = requests
            })
            .observe(on: MainScheduler.instance)
            .catch { error in
                var alert: UIAlertController
                if let localizedTitledError = error as? LocalizedTitledError {
                    alert = UIAlertController.infoAlert(title: localizedTitledError.localizedTitle, message: localizedTitledError.localizedDescription)
                } else {
                    alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Verification.PhoneNumber.requestFailure)
                }
                self.parentViewController.present(alert, animated: true, completion: nil)
                return Maybe.empty()
            }
    }

    private func getNextAllowedRequestTimestamp() -> Double? {
        let timeframe = timeoutBase*pow(2, 4)
        let timeframeBegin = Date().timeIntervalSince1970 - timeframe
        let requestsInTimeoutTimeframe = preferences.verificationRequests

            // Take only entries from current day
            .filter { Date().timeIntervalSince1970 - $0.date.timeIntervalSince1970 < 24.0 * 60.0 * 60.0 }

            .filter { $0.date.timeIntervalSince1970 > timeframeBegin }
        let sorted = requestsInTimeoutTimeframe.sorted(by: { $0.date > $1.date })

        // If there are some requests sent in given timeframe
        if let last = sorted.first {
            let nextTimeframe = timeoutBase * pow(2, Double(requestsInTimeoutTimeframe.count - 1))
            return last.date.timeIntervalSince1970 + nextTimeframe
        }

        // There are no requests in given timeframe
        return nil
    }

}
