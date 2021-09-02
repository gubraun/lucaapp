import UIKit

extension UIViewController {
    func set(title: String, subtitle: String? = nil) {

        let titleFont = subtitle == nil ? FontFamily.Montserrat.bold.font(size: 20) : FontFamily.Montserrat.bold.font(size: 16)
        let subtitleFont = FontFamily.Montserrat.medium.font(size: 12)

        if navigationbarTitleLabel == nil {
            let stackView = UIStackView()
            stackView.axis = .vertical

            let titleLabel = UILabel()
            titleLabel.textColor = UIColor.white
            titleLabel.textAlignment = .center
            titleLabel.tag = 1
            stackView.addArrangedSubview(titleLabel)

            let subtitleLabel = UILabel()
            subtitleLabel.textColor = UIColor.white
            subtitleLabel.textAlignment = .center
            subtitleLabel.tag = 2
            stackView.addArrangedSubview(subtitleLabel)

            navigationItem.titleView = stackView
        }

        navigationbarTitleLabel?.text = title
        navigationbarTitleLabel?.font = titleFont
        navigationbarSubtitleLabel?.text = subtitle
        navigationbarSubtitleLabel?.font = subtitleFont
        navigationbarSubtitleLabel?.isHidden = subtitle == nil
    }

    var navigationbarTitleLabel: UILabel? {
        return navigationItem.titleView?.viewWithTag(1) as? UILabel
    }

    var navigationbarSubtitleLabel: UILabel? {
        return navigationItem.titleView?.viewWithTag(2) as? UILabel
    }
}
