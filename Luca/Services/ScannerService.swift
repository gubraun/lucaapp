import UIKit

class ScannerService {

    private let parentViewController: UIViewController
    private let parentView: UIView
    private var scannerVC: QRScannerViewController?

    var scannerOn = false

    init(view: UIView, presenting viewController: UIViewController) {
        self.parentView = view
        self.parentViewController = viewController
    }

    func startScanner() {
        if scannerVC != nil { return }

        scannerVC = MainViewControllerFactory.createQRScannerViewController()

        if let scanner = scannerVC {
            parentViewController.addChild(scanner)
            parentView.addSubview(scanner.view)
            scanner.didMove(toParent: parentViewController)

            scanner.view.translatesAutoresizingMaskIntoConstraints = false
            scanner.view.topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
            scanner.view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor).isActive = true
            scanner.view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor).isActive = true
            scanner.view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor).isActive = true

            scannerOn.toggle()
        }
    }

    func endScanner() {
        if let scanner = scannerVC, parentView.subviews.contains(scanner.view) {
            scanner.stopRunning()
            scanner.willMove(toParent: nil)
            scanner.view.removeFromSuperview()
            scanner.removeFromParent()
            scannerOn.toggle()
            scannerVC = nil
        }
    }

}
