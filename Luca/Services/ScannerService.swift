import UIKit

class ScannerService {
    private var scannerVC: QRScannerViewController?

    var scannerOn = false

    func startScanner(onParent parent: UIViewController, in view: UIView, type: QRType, onSuccess: (() -> Void)? = nil) {
        if scannerVC != nil { return }

        scannerVC = ViewControllerFactory.Checkin.createQRScannerViewController()
        scannerVC?.type = type
        scannerVC?.onSuccess = onSuccess
        scannerVC?.present(onParent: parent, in: view)
        scannerOn = true
    }

    func endScanner() {
        scannerVC?.remove()
        scannerOn = false
        scannerVC = nil
    }

}
