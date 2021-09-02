import UIKit
import AVFoundation
import RxSwift

class QRScannerViewController: UIViewController {

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    var type: QRType?

    var onSuccess: (() -> Void)?

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

        setupNavigationbar()

        DispatchQueue.main.async {
            self.startScanning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRunning()
    }

    func setupNavigationbar() {
        set(title: L10n.Test.Scanner.title)
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
            self.captureSession.stopRunning()
        }
    }

    private func scanningFailed() {
        let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Camera.Error.scanningFailed)
        self.present(alert, animated: true)
        captureSession = nil
    }

//    private func setNavigationBarToTranslucent() {
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        navigationController?.navigationBar.shadowImage = UIImage()
//        navigationController?.navigationBar.isTranslucent = true
//    }
}
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            stopRunning()

            _ = ServiceContainer.shared.qrProcessingService.processQRCode(qr: stringValue, viewController: self)
                .do(onError: { error in
                    DispatchQueue.main.async {
                        if let titledError = error as? LocalizedTitledError {
                            let alert = UIAlertController.infoAlert(title: titledError.localizedTitle, message: titledError.localizedDescription, onOk: {
                                self.startRunning()
                            })
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }, onCompleted: {
                    guard let success = self.onSuccess else {
                        self.startRunning()
                        return
                    }
                    success()
                }).subscribe()
        }
    }

}
