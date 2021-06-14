import UIKit
import JGProgressHUD
import Alamofire
import RxSwift
import RxAppState
import DeviceKit
import AVFoundation
import LicensesViewController

// swiftlint:disable:next type_body_length
class ContactQRViewController: UIViewController {

    @IBOutlet weak var selfCheckinButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var privateMeetingButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var moreButtonView: UIView!
    @IBOutlet weak var dataAccessView: UIView!
    @IBOutlet weak var qrCodeLabelTopConstraint: NSLayoutConstraint!

    var scannerService: ScannerService!
    private var progressHud = JGProgressHUD.lucaLoading()
    var actionSheet: UIAlertController?
    var onCheckInDisposeBag: DisposeBag?

    private var accessedTraces: [AccessedTraceId] = []

    /// It will be incremented on every error and resetted on viewWillAppear. If the amount of errors surpasses the threshold, an alert will be shown.
    var errorsCount = 0
    var errorsThreshold = 5
    private var dataAccessMargin: CGFloat = 116
    private var noDataAccessMargin: CGFloat = 20

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        scannerService = ScannerService()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        // Setting it to white here instead of LicensesViewController pod
        self.navigationController?.navigationBar.tintColor = .lucaBlack

        // In the case When checking out and returning back to this view controller, stop the scanner if it is still running
        DispatchQueue.main.async(execute: endScanner)

        showCheckinOrMeetingViewController(animated: false)

        errorsCount = 0
        installObservers()

        if !remindIfPhoneNumberNotVerified() {
            remindIfAddressNotFilled()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.removeTransparency()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)

        onCheckInDisposeBag = nil
    }

    @IBAction func dataAccessPressed(_ sender: UITapGestureRecognizer) {

        self.progressHud.show(in: self.view)

        Observable.from(self.accessedTraces)
        .flatMap { AccessedTraceIdPairer.pairAccessedTraceProperties(accessedTraceId: $0) }
        .toArray()
        .map { dictsArray -> [HealthDepartment: [(TraceInfo, Location)]] in
            var retVal: [HealthDepartment: [(TraceInfo, Location)]] = [:]
            dictsArray.forEach { dict in
                dict.forEach { entry in
                    retVal[entry.key] = entry.value
                }
            }
            return retVal
        }
        .flatMap { dict in
            return ServiceContainer.shared.accessedTracesChecker
                .consume(accessedTraces: self.accessedTraces)
                .andThen(Single.just(dict))
            }
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { dict in
                self.showDataAccessAlert(accesses: dict)
            })
            .do(onDispose: { self.progressHud.dismiss() })
            .subscribe()
    }

    func dataAccess() {
        dataAccessView.isHidden = false
        qrCodeLabelTopConstraint.constant = dataAccessMargin
    }

    func hideDataAccess() {
        dataAccessView.isHidden = true
        qrCodeLabelTopConstraint.constant = noDataAccessMargin
    }

    func setupViews() {
        privateMeetingButton.layer.borderColor = UIColor.white.cgColor
        selfCheckinButton.setTitle(L10n.Contact.Qr.Button.selfCheckin, for: .normal)
        descriptionLabel.text = L10n.Checkin.Qr.description
        titleLabel.text = L10n.Checkin.Qr.title
        moreButtonView.accessibilityLabel = L10n.Contact.Qr.Button.more
        moreButtonView.isAccessibilityElement = true
        qrCodeImageView.isAccessibilityElement = true
        qrCodeImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCode
    }

    func setupQrImage(qrCodeData: Data) {

        // Temp QR Code generation.
        let qrCode = QRCodeGenerator.generateQRCode(data: qrCodeData)
        if let qr = qrCode {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQr = qr.transformed(by: transform)

            if qrCodeImageView.image == nil {
                self.qrCodeImageView.alpha = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.qrCodeImageView.alpha = 1.0
                }
            }
            qrCodeImageView.image = UIImage(ciImage: scaledQr)

        }
    }

    func showDataAccessAlert(onOk: (() -> Void)? = nil, accesses: [HealthDepartment: [(TraceInfo, Location)]]) {
        let alert = AlertViewControllerFactory.createDataAccessAlertViewController(accesses: accesses, allAccessesPressed: allAccessesPressed)
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overCurrentContext
        (self.tabBarController ?? self).present(alert, animated: true, completion: nil)
    }

    func allAccessesPressed() {
        let vc = MainViewControllerFactory.createDataAccessViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func selfCheckinPressed(_ sender: UIButton) {
        if !scannerService.scannerOn {
            DispatchQueue.main.async {
                AVCaptureDevice.authorizationStatus(for: .video) == .authorized
                    ? self.startScanner()
                    : AVCaptureDevice.requestAccess(for: .video, completionHandler: self.didGetAccessResult(canAccessCamera:))
            }
            qrCodeImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCodeScanner
        } else {
            DispatchQueue.main.async(execute: endScanner)
            qrCodeImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCode
        }
    }

    func didGetAccessResult(canAccessCamera: Bool) {
        if !canAccessCamera {
            DispatchQueue.main.async(execute: goToApplicationSettings)
        } else {
            DispatchQueue.main.async(execute: startScanner)
        }
    }

    func goToApplicationSettings() {
        UIAlertController(title: L10n.Camera.Access.title, message: L10n.Camera.Access.description, preferredStyle: .alert).goToApplicationSettings(viewController: self, pop: true)
    }

    func startScanner() {
        scannerService.startScanner(onParent: self, in: qrCodeImageView)
        selfCheckinButton.setTitle(L10n.Contact.Qr.Button.closeScanner, for: .normal)
        descriptionLabel.text = L10n.Checkin.Scanner.description
        titleLabel.text = L10n.Checkin.Scanner.title
    }

    func endScanner() {
        scannerService.endScanner()
        selfCheckinButton.setTitle(L10n.Contact.Qr.Button.selfCheckin, for: .normal)
        descriptionLabel.text = L10n.Checkin.Qr.description
        titleLabel.text = L10n.Checkin.Qr.title
    }

    @IBAction func privateMeetingPressed(_ sender: UIButton) {
        UIAlertController(title: L10n.Private.Meeting.Start.title,
                          message: L10n.Private.Meeting.Start.description,
                          preferredStyle: .alert)
            .actionAndCancelAlert(actionText: L10n.Navigation.Basic.start, action: createPrivateMeeting, viewController: self)
    }

    private func createPrivateMeeting() {
        if ServiceContainer.shared.privateMeetingService.currentMeeting == nil {
            _ = ServiceContainer.shared.privateMeetingService.createMeeting()
                .subscribe(on: MainScheduler.instance)
                .do(onSubscribe: { self.progressHud.show(in: self.view) })
                .do(onDispose: { self.progressHud.dismiss() })
                .do(onSuccess: { meeting in
                    let vc = MainViewControllerFactory.createPrivateMeetingViewController(meeting: meeting)
                    self.navigationController?.pushViewController(vc, animated: true)
                })
                .do(onError: { error in
                    let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Private.Meeting.Create.failure(error.localizedDescription))
                    self.present(alert, animated: true, completion: nil)
                })
                .subscribe()
        }
    }

    func showPrivateMeetingViewController() {
        if let meeting = ServiceContainer.shared.privateMeetingService.currentMeeting {
            let viewController = MainViewControllerFactory.createPrivateMeetingViewController(meeting: meeting)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    // swiftlint:disable:next function_body_length
    private func installObservers() {

        let disposeBag = DisposeBag()

        // Observer for the data badge
        ServiceContainer.shared.accessedTracesChecker.accessedTraceIds
            .map { array in array.filter({ !$0.hasBeenSeenByUser }) }
            .logError(self, "Accessed trace IDs")
            .asDriver(onErrorJustReturn: [])
            .do(onNext: { accessedTraces in
                self.accessedTraces = accessedTraces
                if accessedTraces.isEmpty {
                    self.hideDataAccess()
                } else {
                    self.dataAccess()
                }
            })
            .drive()
            .disposed(by: disposeBag)

        ServiceContainer.shared.traceIdService
            .onCheckInRx()
            .asDriver(onErrorDriveWith: .empty())
            .do(onNext: { _ in
                self.log("Checked in!")
                self.showCheckinOrMeetingViewController(animated: true)
            })
            .drive()
            .disposed(by: disposeBag)

        // Trigger checkout reminder if user checks in and has autocheckout off.
        ServiceContainer.shared.traceIdService
            .onCheckInRx()
            .flatMap { _ -> Completable in

                let locationObservable = ServiceContainer.shared.traceIdService.fetchCurrentLocationInfo().asObservable()
                let permissionObservable = NotificationPermissionHandler.shared.notificationSettings.take(1)

                return Observable.zip(locationObservable, permissionObservable) { (location, permission) in

                    NotificationPermissionHandler.shared.setPermissionValue(permission: permission)

                    let autoCheckoutOff = (location.geoLocationRequired && !LucaPreferences.shared.autoCheckout) || !location.geoLocationRequired
                    (permission == .authorized && autoCheckoutOff) ? NotificationService.shared.addNotification() : NotificationService.shared.removePendingNotifications()
                }
                .ignoreElementsAsCompletable()
            }
            .subscribe()
            .disposed(by: disposeBag)

        Observable<Int>.interval(.seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .flatMapFirst { _ in ServiceContainer.shared.traceIdService.fetchTraceStatusRx() }
            .debug("Checking poll")
            .logError(self, "Checkin poll")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .subscribe()
            .disposed(by: disposeBag)

        UIApplication.shared.rx.currentAndChangedAppState
            .flatMapLatest { appState -> Completable in
                if appState != .active {
                    return Completable.empty()
                }
                return LucaPreferences.shared.uuidChanges
                    .unwrapOptional()
                    .flatMapLatest { _ in
                        Observable<Int>.timer(.seconds(0), period: .seconds(10), scheduler: LucaScheduling.backgroundScheduler)
                            .flatMapFirst { _ in self.handleQRCodeGeneration() }
                    }
                    .ignoreElementsAsCompletable()
            }
            .debug("QR Image")
            .logError(self, "QR Image")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .subscribe()
            .disposed(by: disposeBag)

        onCheckInDisposeBag = disposeBag
    }

    private func handleQRCodeGeneration() -> Completable {
        ServiceContainer.shared.traceIdService.getOrCreateQRCode()
            .asObservable()
            .map { $0.qrCodeData }
            .catch({ (error) -> Observable<Data> in

                defer { self.errorsCount += 1 }

                if self.errorsCount < self.errorsThreshold {
                    return Observable<Data>.error(error) // Do not consume, rely on the retry and allow the log to print this error.
                }

                return UIAlertController.infoAlertRx(viewController: self,
                                                     title: L10n.Navigation.Basic.error,
                                                     message: L10n.QrCodeGeneration.Failure.message(error.localizedDescription))
                    .ignoreElementsAsCompletable()
                    .andThen(Observable<Data>.error(error))
                    // Do not consume the error, push it further to cause the restart of the stream. The alerts won't be cumulated as the alert Rx waits until user disposes it.
            })
            .observe(on: MainScheduler.instance)
            .do(onNext: { data in self.setupQrImage(qrCodeData: data) })
            .ignoreElementsAsCompletable()
    }

    /// Returns true if phone number is not verified yet
    private func remindIfPhoneNumberNotVerified() -> Bool {
        if !LucaPreferences.shared.phoneNumberVerified {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.attention, message: L10n.Verification.PhoneNumber.notYetVerified) {
                let viewController = MainViewControllerFactory.createContactViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            }
            present(alert, animated: true, completion: nil)
            return true
        }
        return false
    }

    /// Returns true if data is incomplete
    private func remindIfAddressNotFilled() {
        if !ServiceContainer.shared.userService.isDataComplete {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.attention, message: L10n.UserData.addressNotFilledMessage) {
                let viewController = MainViewControllerFactory.createContactViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            }
            present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func viewMorePressed(_ sender: UITapGestureRecognizer) {
        let resetAction = UIAlertAction(title: L10n.Data.ResetData.title, style: .default) { (_) in
            self.deleteAccountAlert()
        }

        let editContactDataAction = UIAlertAction(title: L10n.UserData.Navigation.edit, style: .default) { (_) in
            let vc = MainViewControllerFactory.createContactViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }

        let additionalActions = [resetAction, editContactDataAction]

        UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
            .dataPrivacyActionSheet(viewController: self, additionalActions: additionalActions)
    }

    func deleteAccountAlert() {
        UIAlertController(title: L10n.Data.ResetData.title,
                          message: L10n.Data.ResetData.description,
                          preferredStyle: .alert)
            .actionAndCancelAlert(actionText: L10n.Data.ResetData.title, action: {
                ServiceContainer.shared.userService.deleteUserData(completion: {
                    DataResetService.resetAll()
                    self.dismiss(animated: true, completion: nil)
                }, failure: { error in
                    // In case account was already deleted, or account doesn't exist, reset app and begin onboarding.
                    if let deleteError = error.error as? DeleteUserError, deleteError == .alreadyDeleted || deleteError == .userNotFound {
                        let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: error.localizedDescription, onOk: { DataResetService.resetAll() })
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: error.localizedDescription)
                        self.present(alert, animated: true, completion: nil)
                    }
                })
            }, viewController: self)
    }

    private func showCheckinOrMeetingViewController(animated: Bool) {
        if ServiceContainer.shared.privateMeetingService.currentMeeting != nil {
            showPrivateMeetingViewController()
            return
        }
        _ = ServiceContainer.shared.traceIdService.currentTraceInfo
            .observeOn(MainScheduler.instance)
            .do(onNext: { traceInfo in
                let viewController = MainViewControllerFactory.createLocationCheckinViewController(traceInfo: traceInfo)
                self.navigationController?.pushViewController(viewController, animated: animated)
            })
            .subscribe()
    }

}

extension ContactQRViewController: UnsafeAddress, LogUtil {}
