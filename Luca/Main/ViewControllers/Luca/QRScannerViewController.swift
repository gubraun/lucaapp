import UIKit
import AVFoundation

class QRScannerViewController: UIViewController {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            self.captureSession = AVCaptureSession()
            self.startScanning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarToTranslucent()
    }
    
    func setNavigationBarToTranslucent() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRunning()
    }
    
    func stopRunning() {
        if let session = captureSession, session.isRunning {
            DispatchQueue.main.async {
                self.captureSession.stopRunning()
            }
        }
    }

    func startScanning() {
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previewLayer != nil {
            previewLayer.frame = view.layer.bounds
        }
    }
    
    func scanningFailed() {
        let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Camera.Error.scanningFailed)
        self.present(alert, animated: true)
        captureSession = nil
    }
    
    func wrongQRCode() {
        let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.Camera.Error.wrongQR)
        self.present(alert, animated: true, completion: nil)
    }
    
}
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            guard let url = URL(string: stringValue) else { return }
            
            if let selfCheckin = CheckInURLParser.parse(url: url) {
                checkin(checkin: selfCheckin)
            } else {
                wrongQRCode()
            }
        }
    }
    
    func checkin(checkin: SelfCheckin) {
        ServiceContainer.shared.selfCheckin.add(selfCheckinPayload: checkin)
        stopRunning()
    }
    
}

