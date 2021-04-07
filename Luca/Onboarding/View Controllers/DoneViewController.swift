import UIKit

class DoneViewController: UIViewController {

    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionLabel.text = L10n.Done.description
    }
    
    @IBAction func okayPressed(_ sender: UIButton) {
        LucaPreferences.shared.donePresented = true
        self.dismiss(animated: true, completion: nil)
    }
    
}
