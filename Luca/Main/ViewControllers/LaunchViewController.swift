import UIKit
import RxSwift

class LaunchViewController: UIViewController {

    var keyAlreadyFetched = false

    var versionCheckerDisposeBag = DisposeBag()

    // It's a safety check if data has been corrupted between updates. Or the initial state
    var dataComplete: Bool {
        LucaPreferences.shared.uuid != nil && ServiceContainer.shared.userService.isPersonalDataComplete
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if fetchDailyKey() {
            launchStoryboard()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if !dataComplete {
            LucaPreferences.shared.welcomePresented = false
            LucaPreferences.shared.dataPrivacyPresented = false
        }

        // Continuous version checker
        ServiceContainer.shared.backendMiscV3.fetchSupportedVersions()
            .asSingle()
            .asObservable()
            .flatMap { supportedVersions in
                Single.from { Bundle.main.buildVersionNumber }
                    .asObservable()
                    .unwrapOptional()
                    .map { Int($0) }
                    .unwrapOptional()
                    .map { $0 >= supportedVersions.minimumVersion  }
            }
            .observeOn(MainScheduler.instance)
            .flatMap { isSupported -> Completable in
                if !isSupported,
                   let topVC = UIApplication.shared.topViewController {

                    return UIAlertController.infoBoxRx(viewController: topVC,
                                                       title: L10n.Navigation.Basic.error,
                                                       message: L10n.VersionSupportChecker.failureMessage)
                        .ignoreElements()

                }
                return Completable.empty()
            }
            .logError(self, "Version support checker")
            .retry(delay: .seconds(10), scheduler: LucaScheduling.backgroundScheduler)
            .subscribe()
            .disposed(by: versionCheckerDisposeBag)
    }

    func launchStoryboard() {

        var viewController: UIViewController!
        if !LucaPreferences.shared.welcomePresented {
            viewController = OnboardingViewControllerFactory.createWelcomeViewController()
        } else if !dataComplete {
            if !LucaPreferences.shared.dataPrivacyPresented {
                viewController = OnboardingViewControllerFactory.createDataPrivacyViewController()
            } else {
                LucaPreferences.shared.userRegistrationData = UserRegistrationData()
                LucaPreferences.shared.currentOnboardingPage = 0
                LucaPreferences.shared.phoneNumberVerified = false
                ServiceContainer.shared.traceIdService.disposeData(clearTraceHistory: true)

                viewController = OnboardingViewControllerFactory.createFormViewController()
            }
        } else if dataComplete && !LucaPreferences.shared.donePresented {
            viewController = OnboardingViewControllerFactory.createDoneViewController()
        } else {
            viewController = MainViewControllerFactory.createTabBarController()
        }
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .crossDissolve
        self.present(viewController, animated: true, completion: nil)
    }

    /// Returns true if there is any daily key. It will be updated anyway, but the app can proceed
    func fetchDailyKey() -> Bool {
        var isAnyKey = false
        if let newestId = ServiceContainer.shared.dailyKeyRepository.newestId,
            (try? ServiceContainer.shared.dailyKeyRepository.restore(index: newestId)) != nil {
            isAnyKey = true
        }
        if keyAlreadyFetched && isAnyKey {
            return true
        }

        ServiceContainer.shared.dailyKeyRepoHandler.fetch {
            self.keyAlreadyFetched = true
            // Continue with UI
            if !isAnyKey {
                DispatchQueue.main.async { self.launchStoryboard() }
            }
        } failure: { (error) in
            if !isAnyKey {
                self.showErrorAlert(for: error)
            }
        }
        return isAnyKey
    }

    private func showErrorAlert(for error: DailyKeyRepoHandlerError) {
        DispatchQueue.main.async {
            let alert = UIAlertController.infoBox(
                title: error.localizedTitle,
                message: error.localizedDescription)

            UIViewController.visibleViewController?.present(alert, animated: true, completion: nil)
        }
    }
}

extension LaunchViewController: UnsafeAddress, LogUtil {}
