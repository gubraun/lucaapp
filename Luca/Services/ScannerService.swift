import UIKit

class ScannerService {
    private var scannerVC: QRScannerViewController?

    var scannerOn = false

    func startScanner(onParent parent: UIViewController, in view: UIView) {
        if scannerVC != nil { return }

        scannerVC = MainViewControllerFactory.createQRScannerViewController()
        scannerVC!.present(onParent: parent, in: view)
        scannerOn = true
    }

    func endScanner() {
        scannerVC?.remove()
        scannerOn = false
        scannerVC = nil
    }

}
