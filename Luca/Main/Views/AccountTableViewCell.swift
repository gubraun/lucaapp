import UIKit

class AccountTableViewCell: UITableViewCell, Identifiable {

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .montserratTableViewTitle
        titleLabel.textColor = .white
        addSubview(titleLabel)

        return titleLabel
    }()

    func configureTitle(_ title: String) {
        titleLabel.text = title
        backgroundColor = .lucaWhiteLowAlpha

        setupConstraints()
    }

    private func setupConstraints() {
        titleLabel.setAnchor(top: topAnchor,
                             leading: leadingAnchor,
                             bottom: nil,
                             trailing: trailingAnchor,
                             padding: .init(top: 16, left: 16, bottom: 0, right: 8))
    }
}
