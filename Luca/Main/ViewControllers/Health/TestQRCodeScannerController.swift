import UIKit
import RxSwift

class TestQRCodeScannerController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButtonView: UIView!
    @IBOutlet private weak var cameraView: UIView!

    private let scannerVC = MainViewControllerFactory.createQRScannerViewController()
    private var disposeBag: DisposeBag?

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraView.layer.cornerRadius = 4
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startScanner()
        setupViews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        endScanner()
    }

    func setupViews() {
        closeButtonView.isAccessibilityElement = true
        closeButtonView.accessibilityLabel = L10n.Test.Scanner.close
        closeButtonView.accessibilityTraits = .button
        cameraView.isAccessibilityElement = true
        cameraView.accessibilityLabel = L10n.Test.Scanner.camera
        self.view.accessibilityElements = [titleLabel, closeButtonView, cameraView].map { $0 as Any }
        UIAccessibility.setFocusLayoutWithDelay(titleLabel)
    }

    @IBAction private func closePressed(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    private func startScanner() {
        scannerVC.mode = .healthTest
        scannerVC.present(onParent: self, in: cameraView)

        scannerVC.onTestResult = { [weak self] urlToParse in
            let alert = AlertViewControllerFactory.createTestPrivacyConsent(confirmAction: {
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
