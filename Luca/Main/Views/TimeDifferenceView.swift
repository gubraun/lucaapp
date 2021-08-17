import UIKit

class TimeDifferenceView: UIView {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }

    private func setup() {
        iconImageView.image = UIImage(named: "infoIcon")?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = UIColor.lucaBlack

        settingsButton.addTarget(self, action: #selector(didPressSettings(sender:)), for: .touchUpInside)
        settingsButton.layer.borderWidth = 1
        settingsButton.layer.borderColor = UIColor.black.cgColor
        settingsButton.layer.cornerRadius = 20
    }
}

// MARK: - Actions

extension TimeDifferenceView {
    @objc
    private func didPressSettings(sender: UIButton) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: nil)
        }
    }
}
