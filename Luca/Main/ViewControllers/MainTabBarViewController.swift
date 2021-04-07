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
        
        let borderView = UIView(frame: CGRect(x: 0, y: 0, width: tabBar.frame.size.width, height: 1))
        borderView.backgroundColor = .lucaGrey
        tabBar.addSubview(borderView)
        
        if let tabBarItems = tabBar.items {
            tabBarItems[0].title = L10n.Navigation.Tab.checkin
            tabBarItems[1].title = L10n.Navigation.Tab.history
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let tabBarItems = tabBar.items {
            tabBar.selectionIndicatorImage = UIImage().createTabBarSelectionIndicator(tabSize: CGSize(width: tabBar.frame.width/CGFloat(tabBarItems.count), height: tabBar.frame.height))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.selectedIndex = 0
        
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
        
        //Continuously check if there is any pending self check in request and consume it if its the case
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
                    .andThen(ServiceContainer.shared.traceIdService.checkInRx(selfCheckin: pendingCheckin.0))
                    .do(onSubscribe: { DispatchQueue.main.async { self.progressHud.show(in: self.view) } })
                    .do(onDispose: { DispatchQueue.main.async { self.progressHud.dismiss() } })
            }
            .ignoreElements()
            .debug("Self checkin")
            .catchError {
                UIAlertController.infoAlertRx(
                    viewController: self,
                    title: L10n.MainTabBarViewController.ScannerFailure.title,
                    message: $0.localizedDescription)
                    .ignoreElements()
                    .andThen(Completable.error($0)) //Push the error through to retry the stream
            }
            .logError(self, "Pending self checkin")
            .retry(delay: .seconds(1), scheduler: MainScheduler.instance)
            .subscribe()
            .disposed(by: disposeBag)
        
        // Check accessed TraceIDs once in app runtime lifecycle
        ServiceContainer.shared.accessedTracesChecker
            .fetchAccessedTraceIds()
            .logError(self, "Accessed Trace Id check")
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposeBag = DisposeBag()
    }

}

extension MainTabBarViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return viewController != tabBarController.selectedViewController
    }

}

extension MainTabBarViewController: UnsafeAddress, LogUtil {}
