import UIKit
import RxSwift

class PrivateMeetingViewController: UIViewController {

    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var guestsLabel: UILabel!
    
    var meeting: PrivateMeetingData! {
        didSet {
            let guests = meeting.guests
                .map { try? ServiceContainer.shared.privateMeetingService.decrypt(guestData: $0, meetingKeyIndex: meeting.keyIndex) }
                .filter { $0 != nil }
                .map { $0! }
                .map { "\($0.fn) \($0.ln)" }
            uniqueGuests = Array(Set(guests))
        }
    }
    
    private var uniqueGuests: [String] = []
    
    var disposeBag: DisposeBag? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        if let url = try? ServiceContainer.shared.privateMeetingQRCodeBuilderV3.build(scannerId: meeting.ids.scannerId).generatedUrl,
           let data = url.data(using: .utf8) {
            setupQrImage(qrCodeData: data)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

        CheckinTimer.shared.delegate = self
        startTimer()
        
        disposeBag = DisposeBag()
        
        Observable<Int>.interval(.seconds(10), scheduler: LucaScheduling.backgroundScheduler)
            .flatMapFirst { _ in ServiceContainer.shared.privateMeetingService.refresh(meeting: self.meeting) }
            .observeOn(MainScheduler.instance)
            .do(onNext: { refreshedMeeting in
                self.meeting = refreshedMeeting
                self.setupViews()
            })
            .logError(self, "Meeting fetch")
            .retry(delay: .seconds(1), scheduler: LucaScheduling.backgroundScheduler)
            .subscribe()
            .disposed(by: disposeBag!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposeBag = nil
    }
    
    func startTimer() {
        CheckinTimer.shared.start(from: meeting.createdAt)
    }

    @IBAction func viewMorePressed(_ sender: UITapGestureRecognizer) {
        UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet).dataPrivacyActionSheet(viewController: self)
    }
    
    @IBAction func endMeetingPressed(_ sender: UIButton) {
        let alert = UIAlertController.yesOrNo(title: L10n.Private.Meeting.End.title, message: L10n.Private.Meeting.End.description, onYes: endMeeting, onNo: nil)
        present(alert, animated: true, completion: nil)
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
    
    @IBAction func meetingInfoButtonPressed(_ sender: UIButton) {
        presentInfoViewController(titleText: L10n.Private.Meeting.Info.title, descriptionText: L10n.Private.Meeting.Info.description)
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
        let viewController = AlertViewControllerFactory.createInfoViewController(titleText: titleText, descriptionText: descriptionText)
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overFullScreen
        present(viewController, animated: true, completion: nil)
    }
    
    func setupViews() {
        self.navigationController?.setTranslucent()
        navigationItem.hidesBackButton = true
        descriptionLabel.text = L10n.Private.Meeting.description
        guestsLabel.text = "\(self.meeting.guests.filter { $0.isCheckedIn }.count)\\\(uniqueGuests.count)"
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
    }
    
}

extension PrivateMeetingViewController: LogUtil, UnsafeAddress {}
