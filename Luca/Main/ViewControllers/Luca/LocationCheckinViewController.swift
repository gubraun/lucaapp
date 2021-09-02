import UIKit
import JGProgressHUD
import CoreLocation
import RxSwift
import RxCocoa
import RxAppState
import StoreKit

class LocationCheckinViewController: UIViewController {

    @IBOutlet weak var checkinSlider: CheckinSlider!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var checkinDateLabel: UILabel!
    @IBOutlet weak var automaticCheckoutSwitch: UISwitch!
    @IBOutlet weak var checkOutLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var tableNumberLabel: UILabel!
    @IBOutlet weak var automaticCheckoutLabel: UILabel!
    @IBOutlet weak var autoCheckoutView: UIView!

    var viewModel: LocationCheckInViewModel!

    var initialStatusBarStyle: UIStatusBarStyle?

    var loadingHUD = JGProgressHUD.lucaLoading()

    var widthSEConstraint: CGFloat = 320

    private var userStatusFetcherDisposeBag: DisposeBag?
    private var checkOutDisposeBag: DisposeBag?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationPermissionHandler.shared.requestAuthorization(viewController: self)

        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setTranslucent()
        navigationbarTitleLabel?.textColor = UIColor.black
        navigationbarSubtitleLabel?.textColor = UIColor.black

        initialStatusBarStyle = UIApplication.shared.statusBarStyle
        if #available(iOS 13.0, *) {
            UIApplication.shared.setStatusBarStyle(.darkContent, animated: animated)
        } else {
            UIApplication.shared.setStatusBarStyle(.default, animated: animated)
        }
        setupAccessibility()

        installObservers()
        print("TEST: Will appear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.removeTransparency()
        navigationbarTitleLabel?.textColor = UIColor.white
        navigationbarSubtitleLabel?.textColor = UIColor.white

        removeObservers()

        if let statusBarStyle = initialStatusBarStyle {
            UIApplication.shared.setStatusBarStyle(statusBarStyle, animated: animated)
        }

        userStatusFetcherDisposeBag = nil
        sliderWasSetup = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupCheckinSlider()
    }

    @IBAction func autoCheckoutViewPressed(_ sender: UITapGestureRecognizer) {
        guard autoCheckoutView.accessibilityElementIsFocused() && UIAccessibility.isVoiceOverRunning else { return }
        let isOn = automaticCheckoutSwitch.isOn
        automaticCheckoutSwitch.setOn(!isOn, animated: true)
        viewModel.isAutoCheckoutEnabled.accept(automaticCheckoutSwitch.isOn)
        let switchState = automaticCheckoutSwitch.isOn ? L10n.LocationCheckinViewController.AutoCheckout.on : L10n.LocationCheckinViewController.AutoCheckout.off
        autoCheckoutView.accessibilityLabel = "\(L10n.LocationCheckinViewController.autoCheckout) \(switchState)"
    }

    @objc private func checkoutForAccessibility() -> Bool {
        checkout()
        return true
    }

    private func checkout() {
        if checkOutDisposeBag != nil {
            return
        }

        showAppStoreReview()

        let disposeBag = DisposeBag()

        viewModel.checkOut()
            .observe(on: MainScheduler.instance)
            .logError(self, "Check out")
            .do(onError: { (error) in
                if let printableError = error as? PrintableError {
                    let alert = UIAlertController.infoAlert(
                        title: printableError.title,
                        message: printableError.message)
                    self.present(alert, animated: true, completion: nil)
                } else if let localizedError = error as? LocalizedTitledError {
                    let alert = UIAlertController.infoAlert(
                        title: localizedError.localizedTitle,
                        message: localizedError.localizedDescription)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController.infoAlert(
                        title: L10n.Navigation.Basic.error,
                        message: L10n.General.Failure.Unknown.message(error.localizedDescription))
                    self.present(alert, animated: true, completion: nil)
                }
            }, onDispose: {
                self.checkOutDisposeBag = nil
            })
            .onErrorComplete()
            .subscribe()
            .disposed(by: disposeBag)

        checkOutDisposeBag = disposeBag
    }

    private func resetCheckInSlider() {
        checkinSlider.reset()
        checkOutLabel.isHidden = false
        checkOutLabel.alpha = 1.0
    }

    private var sliderWasSetup = false
    private func setupCheckinSlider() {
        guard !sliderWasSetup else { return }
        resetCheckInSlider()
        sliderWasSetup = true
    }

    func showAppStoreReview() {
        LucaPreferences.shared.appStoreReviewCheckoutCounter += 1
        if LucaPreferences.shared.appStoreReviewCheckoutCounter % 5 == 0 {
            SKStoreReviewController.requestReview()
        }
    }

    // MARK: View setup functions.

    func setupViews() {
        if view.frame.size.width <= widthSEConstraint {
            timerLabel.font = UIFont.montserratRegularTimer
        }

        welcomeLabel.text = L10n.LocationCheckinViewController.welcomeMessage
        navigationItem.hidesBackButton = true
        // set dummy title. Will be changed later
        set(title: "")
    }

    // swiftlint:disable:next function_body_length
    private func installObservers() {

        let newDisposeBag = DisposeBag()

        viewModel.isCheckedIn
            .do { (isCheckedIn) in
                if !isCheckedIn {
                    self.navigationController?.popViewController(animated: true)
                    self.removeObservers()
                }
            }
            .drive()
            .disposed(by: newDisposeBag)

        viewModel.isBusy.do { (busy) in
            if busy {
                self.loadingHUD.show(in: self.view)
            } else {
                self.loadingHUD.dismiss()
            }
        }
        .drive()
        .disposed(by: newDisposeBag)

        viewModel.alert
            .asObservable()
            .flatMapFirst { alert in
                return UIAlertController.infoAlertRx(viewController: self, title: alert.title, message: alert.message)
            }
            .subscribe()
            .disposed(by: newDisposeBag)

        viewModel.additionalDataLabelHidden
            .drive(tableNumberLabel.rx.isHidden)
            .disposed(by: newDisposeBag)

        viewModel.additionalDataLabelText
            .drive(tableNumberLabel.rx.text)
            .disposed(by: newDisposeBag)

        viewModel.time
            .drive(self.timerLabel.rx.text)
            .disposed(by: newDisposeBag)

        viewModel.isAutoCheckoutAvailable
            .map { !$0 }
            .drive(self.automaticCheckoutSwitch.rx.isHidden)
            .disposed(by: newDisposeBag)

        viewModel.isAutoCheckoutAvailable
            .map { !$0 }
            .drive(self.automaticCheckoutLabel.rx.isHidden)
            .disposed(by: newDisposeBag)

        viewModel.isAutoCheckoutAvailable
            .asObservable()
            .subscribe(onNext: { isAvailable in
                self.autoCheckoutView.isAccessibilityElement = isAvailable
            })
            .disposed(by: newDisposeBag)

        viewModel.checkInTime
            .drive(checkinDateLabel.rx.text)
            .disposed(by: newDisposeBag)

        Driver.combineLatest(viewModel.groupName, viewModel.locationName).drive(onNext: { [weak self] (groupName, locationName) in
            self?.setupLocationLabels(with: groupName, and: locationName)
        }).disposed(by: newDisposeBag)

        (automaticCheckoutSwitch.rx.value <-> viewModel.isAutoCheckoutEnabled).disposed(by: newDisposeBag)

        checkinSlider.valueObservable.subscribe(onNext: { value in
            self.checkOutLabel.alpha = value
        }).disposed(by: newDisposeBag)

        checkinSlider.completed.subscribe(onNext: { completed in
            self.resetCheckInSlider()
            if completed {
                self.checkout()
            }
        }).disposed(by: newDisposeBag)

        viewModel.checkInTimeDate
            .subscribe(onSuccess: { time in
                self.checkinDateLabel.accessibilityLabel = L10n.Checkin.Slider.date(time.accessibilityDate)
            })
             .disposed(by: newDisposeBag)

        viewModel.connect(viewController: self)

        userStatusFetcherDisposeBag = newDisposeBag

        print("TEST: Install observers")
    }

    private func removeObservers() {
        userStatusFetcherDisposeBag = nil
        viewModel.release()
        print("TEST: Remove observers")
    }

    private func setupLocationLabels(with groupName: String?, and locationName: String?) {
        switch (groupName, locationName) {
        case (.some(let groupName), .some(let locationName)):
            set(title: locationName, subtitle: groupName)
        case (.some(let groupName), nil):
            set(title: groupName)
        default:
            break
        }

        UIAccessibility.setFocusTo(navigationbarTitleLabel, notification: .layoutChanged)
    }
}

extension LocationCheckinViewController: UnsafeAddress, LogUtil {}

// MARK: - Accessibility
extension LocationCheckinViewController {

    private func setupAccessibility() {
        checkinSlider.sliderType = .location

        autoCheckoutView.accessibilityTraits = automaticCheckoutSwitch.accessibilityTraits
        navigationbarTitleLabel!.accessibilityTraits = .header
        navigationbarSubtitleLabel!.accessibilityTraits = .header

        autoCheckoutView.isAccessibilityElement = true
        timerLabel.isAccessibilityElement = false

        UIAccessibility.setFocusTo(navigationbarTitleLabel, notification: .layoutChanged, delay: 0.8)

        let switchState = automaticCheckoutSwitch.isOn ? L10n.LocationCheckinViewController.AutoCheckout.on : L10n.LocationCheckinViewController.AutoCheckout.off
        autoCheckoutView.accessibilityLabel = "\(L10n.LocationCheckinViewController.autoCheckout) \(switchState)"

        setupAccessibilityAutocheckoutAction()

        self.view.accessibilityElements = [welcomeLabel, checkinDateLabel, tableNumberLabel, autoCheckoutView, checkinSlider.sliderImage].map { $0 as Any }
    }

    private func setupAccessibilityAutocheckoutAction() {
        let accessibilityCompleteAction = UIAccessibilityCustomAction(
            name: L10n.LocationCheckinViewController.Accessibility.directCheckout,
            target: self,
            selector: #selector(checkoutForAccessibility))

        accessibilityCustomActions = [accessibilityCompleteAction]
    }
}
