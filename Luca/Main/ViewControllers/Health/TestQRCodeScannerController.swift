import UIKit
import RxSwift

class TestQRCodeScannerController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet private weak var cameraView: UIView!

    private let scannerVC = ViewControllerFactory.Checkin.createQRScannerViewController()
    private var disposeBag: DisposeBag?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAccessibility()
        startScanner()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        endScanner()
    }

    func setupViews() {
        cameraView.layer.cornerRadius = 4
    }

    @IBAction func closeButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    private func startScanner() {
        scannerVC.mode = .healthTest
        scannerVC.present(onParent: self, in: cameraView)

        scannerVC.onTestResult = { [weak self] urlToParse in
            let alert = ViewControllerFactory.Alert.createTestPrivacyConsent(confirmAction: {
                self?.parseQRCode(urlToParse: urlToParse)
            }, cancelAction: {
                self?.scannerVC.startRunning()
            })
            alert.modalTransitionStyle = .crossDissolve
            alert.modalPresentationStyle = .overCurrentContext
            self?.present(alert, animated: true, completion: nil)
        }
    }

    private func parseQRCode(urlToParse: String) {
        let newDisposeBag = DisposeBag()
        ServiceContainer.shared.documentProcessingService.parseQRCode(qr: urlToParse)
            .observe(on: MainScheduler.instance)
            .do(onError: { error in
                self.presentScannerErrorAlert(for: error)
            }, onCompleted: {
                self.dismiss(animated: true, completion: nil)
            }).subscribe().disposed(by: newDisposeBag)

        self.disposeBag = newDisposeBag
    }

    func endScanner() {
        scannerVC.remove()
        disposeBag = nil
    }

    private func presentScannerErrorAlert(for error: Error) {
        if let localizedError = error as? LocalizedTitledError {
            let alert = UIAlertController.infoAlert(title: localizedError.localizedTitle, message: localizedError.localizedDescription, onOk: {
                self.scannerVC.startRunning()
            })
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.General.Failure.Unknown.message(error.localizedDescription), onOk: {
                self.scannerVC.startRunning()
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - Accessibility
extension TestQRCodeScannerController {

    private func setupAccessibility() {
        closeButton.accessibilityLabel = L10n.Test.Scanner.close
        cameraView.accessibilityLabel = L10n.Test.Scanner.camera
        cameraView.isAccessibilityElement = true
        self.view.accessibilityElements = [titleLabel, closeButton, descriptionLabel, cameraView].map { $0 as Any }
        UIAccessibility.setFocusTo(titleLabel, notification: .layoutChanged, delay: 0.8)
    }

}
