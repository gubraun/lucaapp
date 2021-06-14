import UIKit
import AVFoundation
import RxSwift

class QRScannerViewController: UIViewController {
    enum Mode {
        case checkIn
        case healthTest
    }

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    var onTestResult: ((String) -> Void)?
    var mode = Mode.checkIn

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession = AVCaptureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previewLayer != nil {
            previewLayer.frame = view.layer.bounds
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarToTranslucent()

        DispatchQueue.main.async {
            self.startScanning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRunning()
    }

    // MARK: - Public interface
    func remove() {
        stopRunning()

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    func present(onParent parent: UIViewController, in parentView: UIView) {
        parent.addChild(self)
        parentView.addSubview(self.view)
        didMove(toParent: parent)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor).isActive = true
    }

    // MARK: - Private helper
    private func startScanning() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            scanningFailed()
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            scanningFailed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            scanningFailed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        DispatchQueue.main.async {
            self.captureSession.startRunning()
        }
    }

    func startRunning() {
        self.captureSession.startRunning()
    }

    private func stopRunning() {
        if let session = captureSession, session.isRunning {
            DispatchQueue.main.async {
                self.captureSession.stopRunning()
            }
        }
    }

    private func scanningFailed() {
        let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Camera.Error.scanningFailed)
        self.present(alert, animated: true)
        captureSession = nil
    }

    private func wrongQRCode() {
        let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Camera.Error.wrongQR, onOk: {
            self.startRunning()
        })
        self.present(alert, animated: true, completion: nil)
    }

    private func wrongScanner() {
        let alert = UIAlertController.infoAlert(title: L10n.Test.Scanner.WrongScanner.title, message: L10n.Test.Scanner.WrongScanner.description)
        self.present(alert, animated: true, completion: nil)
    }

    private func setNavigationBarToTranslucent() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }
}
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            stopRunning()

            switch mode {
            case .checkIn:
                if let url = URL(string: stringValue), let selfCheckin = CheckInURLParser.parse(url: url) {
                    checkin(checkin: selfCheckin)
                } else if let url = URL(string: stringValue), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    wrongQRCode()
                }
            case .healthTest:
                if let url = URL(string: stringValue), CheckInURLParser.parse(url: url) != nil {
                    wrongScanner()
                } else if let onResult = onTestResult {
                    onResult(stringValue)
                } else if let url = URL(string: stringValue), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    wrongQRCode()
                }
            }
        }
    }

    func checkin(checkin: SelfCheckin) {
        ServiceContainer.shared.selfCheckin.add(selfCheckinPayload: checkin)
    }

}
