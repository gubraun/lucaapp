import UIKit
import JGProgressHUD
import CoreLocation
import RxSwift
import RxCocoa
import RxAppState
import MessageUI
import DeviceKit

class LocationCheckinViewController: UIViewController {

    @IBOutlet weak var checkinSlider: CheckinSlider!
    @IBOutlet weak var sliderDescriptionLabel: UILabel!
    @IBOutlet weak var checkinDateLabel: UILabel!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var automaticCheckoutSwitch: UISwitch!
    @IBOutlet weak var checkOutLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var tableNumberLabel: UILabel!
    @IBOutlet weak var automaticCheckoutLabel: UILabel!
    @IBOutlet weak var moreButtonView: UIView!

    var viewModel: LocationCheckInViewModel!

    var initialStatusBarStyle: UIStatusBarStyle?

    var loadingHUD = JGProgressHUD.lucaLoading()

    var widthSEConstraint: CGFloat = 320

    private var autoCheckoutDisposeBag = DisposeBag()
    private var userStatusFetcherDisposeBag: DisposeBag?
    private var checkOutDisposeBag: DisposeBag?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setTranslucent()

        NotificationPermissionHandler.shared.requestAuthorization(viewController: self)

        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

        UIAccessibility.setFocusTo(locationNameLabel)

        initialStatusBarStyle = UIApplication.shared.statusBarStyle
        if #available(iOS 13.0, *) {
            UIApplication.shared.setStatusBarStyle(.darkContent, animated: animated)
        } else {
            UIApplication.shared.setStatusBarStyle(.default, animated: animated)
        }

        installObservers()
        print("TEST: Will appear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)

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

    @objc private func checkoutForAccessibility() -> Bool {
        checkout()
        return true
    }

    private func checkout() {
        if checkOutDisposeBag != nil {
            return
        }

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

    @IBAction func viewMorePressed(_ sender: UITapGestureRecognizer) {
        let supportAction = UIAlertAction(title: L10n.General.support, style: .default) { (_) in
            self.sendSupportEmail(viewController: self)
        }

        let additionalActions = [supportAction]

        UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet).dataPrivacyActionSheet(viewController: self, additionalActions: additionalActions)
    }

    func sendSupportEmail(viewController: UIViewController) {
        if MFMailComposeViewController.canSendMail() {
            let version = UIApplication.shared.applicationVersion ?? ""
            let messageBody = L10n.General.Support.Email.body(Device.current.description, UIDevice.current.systemVersion, version)

            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([L10n.General.Support.email])
            mail.setMessageBody(messageBody, isHTML: true)
            present(mail, animated: true)
        } else {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.General.Support.error)
            self.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: View setup functions.

    func setupViews() {
        if view.frame.size.width <= widthSEConstraint {
            sliderDescriptionLabel.font = UIFont.montserratRegularTimer
        }

        welcomeLabel.text = L10n.LocationCheckinViewController.welcomeMessage
        navigationItem.hidesBackButton = true

        sliderDescriptionLabel.isAccessibilityElement = false
        moreButtonView.accessibilityLabel = L10n.Contact.Qr.Button.more
        moreButtonView.isAccessibilityElement = true

        let accessibilityCompleteAction = UIAccessibilityCustomAction(
            name: L10n.LocationCheckinViewController.Accessibility.directCheckout,
            target: self,
            selector: #selector(checkoutForAccessibility))

        accessibilityCustomActions = [accessibilityCompleteAction]
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
            .drive(self.sliderDescriptionLabel.rx.text)
            .disposed(by: newDisposeBag)

        viewModel.isAutoCheckoutAvailable
            .map { !$0 }
            .drive(self.automaticCheckoutSwitch.rx.isHidden)
            .disposed(by: newDisposeBag)

        viewModel.isAutoCheckoutAvailable
            .map { !$0 }
            .drive(self.automaticCheckoutLabel.rx.isHidden)
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
            groupNameLabel.text = groupName
            locationNameLabel.text = locationName
            locationNameLabel.textColor = .black
        case (.some(let groupName), nil):
            groupNameLabel.text = nil
            locationNameLabel.text = groupName
            locationNameLabel.textColor = .black
        default:
            break
        }
    }
}

extension LocationCheckinViewController: UnsafeAddress, LogUtil {}

extension LocationCheckinViewController: MFMailComposeViewControllerDelegate {

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }

}
