import UIKit
import RxSwift

class TestQRCodeScannerController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet private weak var cameraView: UIView!

    var scannerService: ScannerService?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAccessibility()
        scannerService = ScannerService()
        scannerService?.startScanner(onParent: self, in: cameraView, type: .document, onSuccess: { DispatchQueue.main.async { self.dismiss(animated: true, completion: nil) } })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scannerService?.endScanner()
        scannerService = nil
    }

    func setupViews() {
        cameraView.layer.cornerRadius = 4
    }

    @IBAction func closeButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
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
