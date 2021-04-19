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

    @IBAction func viewPressed(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

}
