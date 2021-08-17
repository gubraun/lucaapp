import UIKit
import RxSwift

class PrivateMeetingViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var guestsLabel: UILabel!
    @IBOutlet weak var slider: CheckinSlider!
    @IBOutlet weak var sliderLabel: UILabel!
    @IBOutlet weak var lengthStackView: UIStackView!
    @IBOutlet weak var guestsStackView: UIStackView!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var endMeetingLabel: UILabel!

    var initialStatusBarStyle: UIStatusBarStyle?

    var meeting: PrivateMeetingData! {
        didSet {
            let guests = meeting.guests
                .map { try? ServiceContainer.shared.privateMeetingService.decrypt(guestData: $0, meetingKeyIndex: meeting.keyIndex) }
                .filter { $0 != nil }
                .map { $0! }
                .map { "\($0.fn) \($0.ln)" }
            uniqueGuests = Array(Set(guests))

            if meeting != nil && infoButton != nil {
                infoButton.isHidden = uniqueGuests.isEmpty
            }
            if guestsStackView != nil && meeting != nil {
                guestsStackView.isAccessibilityElement = true
                guestsStackView.accessibilityLabel = L10n.Private.Meeting.Accessibility.guests(meeting.guests.filter { $0.isCheckedIn }.count, uniqueGuests.count)
            }
        }
    }

    private var uniqueGuests: [String] = []

    var disposeBag: DisposeBag?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        infoButton.isHidden = true
        if let url = try? ServiceContainer.shared.privateMeetingQRCodeBuilderV3.build(scannerId: meeting.ids.scannerId).generatedUrl,
           let data = url.data(using: .utf8) {
            setupQrImage(qrCodeData: data)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        UIAccessibility.setFocusTo(titleLabel, notification: .layoutChanged, delay: 0.8)

        initialStatusBarStyle = UIApplication.shared.statusBarStyle
        if #available(iOS 13.0, *) {
            UIApplication.shared.setStatusBarStyle(.darkContent, animated: animated)
        } else {
            UIApplication.shared.setStatusBarStyle(.default, animated: animated)
        }

        CheckinTimer.shared.delegate = self
        startTimer()
        installObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        sliderWasSetup = false

        if let statusBarStyle = initialStatusBarStyle {
            UIApplication.shared.setStatusBarStyle(statusBarStyle, animated: animated)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposeBag = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupSlider()
    }

    func installObservers() {
        let newDisposeBag = DisposeBag()

        Observable<Int>.timer(.seconds(1), period: .seconds(10), scheduler: LucaScheduling.backgroundScheduler)
            .flatMapFirst { _ in ServiceContainer.shared.privateMeetingService.refresh(meeting: self.meeting) }
            .observe(on: MainScheduler.instance)
            .do(onNext: { refreshedMeeting in
                self.meeting = refreshedMeeting
                self.setupViews()
            })
            .logError(self, "Meeting fetch")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .subscribe()
            .disposed(by: newDisposeBag)

        slider.valueObservable.subscribe(onNext: { value in
            self.sliderLabel.alpha = value
        }).disposed(by: newDisposeBag)

        slider.completed.subscribe(onNext: { completed in
            self.resetCheckInSlider()
            if completed {
                let alert = UIAlertController.yesOrNo(title: L10n.Private.Meeting.End.title, message: L10n.Private.Meeting.End.description, onYes: self.endMeeting, onNo: nil)
                self.present(alert, animated: true, completion: nil)
            }
        }).disposed(by: newDisposeBag)
        disposeBag = newDisposeBag
    }

    func startTimer() {
        CheckinTimer.shared.start(from: meeting.createdAt)
    }

    private func resetCheckInSlider() {
        slider.reset()
        sliderLabel.isHidden = false
        sliderLabel.alpha = 1.0
    }

    private var sliderWasSetup = false
    private func setupSlider() {
        guard !sliderWasSetup else { return }
        resetCheckInSlider()
        sliderWasSetup = true
    }

    func endMeeting() {
        ServiceContainer.shared.privateMeetingService.close(meeting: meeting) {
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
                CheckinTimer.shared.stop()
            }
        } failure: { (error) in
            DispatchQueue.main.async {
                let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Private.Meeting.End.failure(error.localizedDescription))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    @IBAction func participantInfoButtonPressed(_ sender: UIButton) {
        let list = uniqueGuests.reduce("") { (result, guest) -> String in
            if result == "" {
                return guest
            } else {
                return "\(result)\n\(guest)"
            }
        }
        presentInfoViewController(titleText: L10n.Private.Meeting.Participants.title, descriptionText: list)
    }

    func presentInfoViewController(titleText: String, descriptionText: String) {
        let viewController = ViewControllerFactory.Alert.createInfoViewController(titleText: titleText, descriptionText: descriptionText)
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overFullScreen
        present(viewController, animated: true, completion: nil)
    }

    func setupViews() {
        self.navigationController?.setTranslucent()
        navigationItem.hidesBackButton = true
        descriptionLabel.text = L10n.Private.Meeting.description
        guestsLabel.text = "\(self.meeting.guests.filter { $0.isCheckedIn }.count)\\\(uniqueGuests.count)"
        slider.sliderType = .privateMeeting
        setupAccessibility()
    }

    func setupQrImage(qrCodeData: Data) {

        // Temp QR Code generation.
        let qrCode = QRCodeGenerator.generateQRCode(data: qrCodeData)
        if let qr = qrCode {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQr = qr.transformed(by: transform)

            if qrImageView.image == nil {
                self.qrImageView.alpha = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.qrImageView.alpha = 1.0
                }
            }
            qrImageView.image = UIImage(ciImage: scaledQr)

        }
    }

}

extension PrivateMeetingViewController: TimerDelegate {

    func timerDidTick() {
        timerLabel.text = CheckinTimer.shared.counter.formattedTimeString
        lengthStackView.isAccessibilityElement = true
        lengthStackView.accessibilityLabel = L10n.Private.Meeting.Accessibility.length(CheckinTimer.shared.counter.formattedTimeString)
    }

}

extension PrivateMeetingViewController: LogUtil, UnsafeAddress {}

// MARK: - Accessibility
extension PrivateMeetingViewController {

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header
        qrImageView.isAccessibilityElement = true
        lengthStackView.isAccessibilityElement = true
        guestsStackView.isAccessibilityElement = true

        qrImageView.accessibilityLabel = L10n.Contact.Qr.Accessibility.qrCode
        if let text = timerLabel.text {
            lengthStackView.accessibilityLabel = L10n.Private.Meeting.Accessibility.length(text)
        }

        let guests = self.meeting.guests.filter { $0.isCheckedIn }.count
        let totalGuests = uniqueGuests.count
        guestsStackView.accessibilityLabel = L10n.Private.Meeting.Accessibility.guests(guests, totalGuests)

        self.view.accessibilityElements = [titleLabel, descriptionLabel, qrImageView, lengthStackView, guestsStackView, infoButton, slider.sliderImage].map { $0 as Any}
    }

}
