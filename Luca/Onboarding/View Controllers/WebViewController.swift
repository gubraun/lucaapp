import UIKit
import WebKit

class WebViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var closeButton: UIButton!
    
    var url: URL!
    override func viewDidLoad() {
        webView.load(URLRequest(url: url))
        
        // Hide the button if on 13.0 or newer (modal view controllers can be closed with a pull-down gesture)
        if #available(iOS 13.0, *) {
            closeButton.isHidden = true
        } else {
            closeButton.isHidden = false
        }
    }
    
    @IBAction private func onCloseButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
