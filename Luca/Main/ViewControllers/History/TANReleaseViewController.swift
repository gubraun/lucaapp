import UIKit
import JGProgressHUD

class TANReleaseViewController: UIViewController {
    
    @IBOutlet weak var tanLabel: UILabel!
    
    var progressHud = JGProgressHUD.lucaLoading()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setTranslucent()
        self.tanLabel.alpha = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(1000)) {
            
            //If its still loading, present the HUD
            if self.tanLabel.alpha == 0.0 {
                self.progressHud.show(in: self.view)
            }
        }
        
        ServiceContainer.shared.userService.transferUserData { (challengeId) in
            
            let formattedString = challengeId
                .uppercased()
                .split(every: 4)
                .reduce("") { (res, group) in
                    return "\(res)-\(group)"
                }
                .dropFirst()
            
            DispatchQueue.main.async {
                self.progressHud.dismiss()
                
                self.tanLabel.text = String(formattedString.uppercased())
                UIView.animate(withDuration: 0.3) {
                    self.tanLabel.alpha = 1.0
                }
            }
        } failure: { (error) in
            self.log("Error loading challenge ID: \(error)", entryType: .error)
            DispatchQueue.main.async {
                let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.DataRelease.Tan.Failure.message(error.localizedDescription)) {
                    self.dismiss(animated: true, completion: nil)
                }
                self.present(alert, animated: true, completion: nil)
            }
        }

    }
    
    @IBAction func dataReleasePressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension TANReleaseViewController: LogUtil, UnsafeAddress {}
