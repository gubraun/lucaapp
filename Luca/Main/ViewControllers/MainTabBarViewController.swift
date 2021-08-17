import UIKit
import RxSwift
import JGProgressHUD
import Alamofire

class MainTabBarViewController: UITabBarController {

    private var disposeBag = DisposeBag()

    private var progressHud = JGProgressHUD.lucaLoading()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        tabBar.barTintColor = .black
        tabBar.backgroundColor = .black
        tabBar.tintColor = .white
        tabBar.isTranslucent = false

        let borderView = UIView(frame: CGRect(x: 0, y: 0, width: tabBar.frame.size.width, height: 1))
        borderView.backgroundColor = .lucaGrey
        tabBar.addSubview(borderView)

        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let tabBarItems = tabBar.items {
            tabBar.selectionIndicatorImage = UIImage().createTabBarSelectionIndicator(tabSize: CGSize(width: tabBar.frame.width/CGFloat(tabBarItems.count), height: tabBar.frame.height))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.selectedIndex = 1

        ServiceContainer.shared.userService.registerIfNeeded { result in
            if result == .userRecreated {
                ServiceContainer.shared.traceIdService.disposeData(clearTraceHistory: true)
            }
            DispatchQueue.main.async { self.progressHud.dismiss() }
        } failure: { (error) in
            DispatchQueue.main.async {
                self.progressHud.dismiss()
                let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error,
                                                        message: error.localizedDescription)
                self.present(alert, animated: true, completion: nil)
            }
        }

        subscribeToSelfCheckin()

        // Check accessed TraceIDs once in app runtime lifecycle
        ServiceContainer.shared.accessedTracesChecker
            .fetchAccessedTraceIds()
            .logError(self, "Accessed Trace Id check")
            .subscribe()
            .disposed(by: disposeBag)

        ServiceContainer.shared.documentProcessingService
            .deeplinkStore
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { deepLink in
                if !deepLink.isEmpty {
                    self.parseQRCode(testString: deepLink)
                }
            })
            .disposed(by: disposeBag)

        // If app was terminated
        if ServiceContainer.shared.privateMeetingService.currentMeeting != nil {
            self.selectedIndex = 0
        }
        _ = ServiceContainer.shared.traceIdService.isCurrentlyCheckedIn
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { checkedIn in
                if checkedIn { self.selectedIndex = 0 }
            })
            .subscribe()
            .disposed(by: disposeBag)

        // If entering app from background
        UIApplication.shared.rx.applicationWillEnterForeground
            .flatMap { _ -> Single<(Bool)> in
                ServiceContainer.shared.traceIdService.isCurrentlyCheckedIn.map { checkedIn -> (Bool) in
                    let privateMeeting = ServiceContainer.shared.privateMeetingService.currentMeeting != nil
                    return (checkedIn || privateMeeting)
                }
            }.asObservable()
            .observe(on: MainScheduler.instance)
            .do(onNext: { checkedIn in
                if checkedIn { self.selectedIndex = 0 }
            }).subscribe()
            .disposed(by: disposeBag)
    }

    private func parseQRCode(testString: String) {
        let alert = ViewControllerFactory.Alert.createTestPrivacyConsent(confirmAction: {
            ServiceContainer.shared.documentProcessingService
                .parseQRCode(qr: testString)
                .subscribe(onError: { error in
                    self.presentErrorAlert(for: error)
                })
                .disposed(by: self.disposeBag)
        })
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overCurrentContext
        present(alert, animated: true, completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposeBag = DisposeBag()
    }

    private func presentErrorAlert(for error: Error) {
        if let localizedError = error as? LocalizedTitledError {
            let alert = UIAlertController.infoAlert(title: localizedError.localizedTitle, message: localizedError.localizedDescription)
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.General.Failure.Unknown.message(error.localizedDescription))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func subscribeToSelfCheckin() {
        // Continuously check if there is any pending self check in request and consume it if its the case
        ServiceContainer.shared.selfCheckin
            .pendingSelfCheckinRx
            .flatMap { pendingCheckin -> Observable<(SelfCheckin, Bool)> in
                if let privateCheckin = pendingCheckin as? PrivateMeetingSelfCheckin {
                    return UIAlertController.okAndCancelAlertRx(viewController: self, title: L10n.Navigation.Basic.hint, message: L10n.Private.Meeting.Alert.description).map { (privateCheckin, $0) }
                }
                return Observable.of((pendingCheckin, true))
            }
            .filter { $0.1 }
            .flatMap { pendingCheckin in
                return Completable.from { ServiceContainer.shared.selfCheckin.consumeCurrent() }
                    .andThen(ServiceContainer.shared.traceIdService.checkIn(selfCheckin: pendingCheckin.0))
                    .do(onSubscribe: {
                            DispatchQueue.main.async {
                                self.progressHud.show(in: self.view)
                                self.selectedIndex = 0
                            }
                    })
                    .do(onDispose: { DispatchQueue.main.async { self.progressHud.dismiss() } })
            }
            .ignoreElementsAsCompletable()
            .debug("Self checkin")
            .catch {
                self.rxErrorAlert(for: $0)
            }
            .logError(self, "Pending self checkin")
            .retry(delay: .seconds(1), scheduler: MainScheduler.instance)
            .subscribe()
            .disposed(by: disposeBag)

    }

    private func rxErrorAlert(for error: Error) -> Completable {
        UIAlertController.infoAlertRx(
            viewController: self,
            title: L10n.MainTabBarViewController.ScannerFailure.title,
            message: error.localizedDescription)
            .ignoreElementsAsCompletable()
            .andThen(Completable.error(error)) // Push the error through to retry the stream
    }
}

extension MainTabBarViewController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return viewController != tabBarController.selectedViewController
    }

}

extension MainTabBarViewController: UnsafeAddress, LogUtil {}
