import UIKit

class InfoViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    var titleText: String!
    var descriptionText: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = titleText
        descriptionLabel.text = descriptionText
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIAccessibility.setFocusTo(titleLabel, notification: .layoutChanged)
    }

    @IBAction func viewPressed(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func okButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
