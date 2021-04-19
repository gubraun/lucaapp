import UIKit

class NewDataAccessHeaderView: UITableViewHeaderFooterView {

    let titleLabel = UILabel()
    let departmentLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureContents()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configureContents() {
        contentView.backgroundColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        departmentLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(departmentLabel)

        titleLabel.text = L10n.Data.Access.title
        titleLabel.textColor = .black
        titleLabel.font = UIFont.montserratTableViewTitle
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true

        departmentLabel.textColor = .black
        departmentLabel.font = UIFont.montserratTableViewDescription
        departmentLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        departmentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
    }

}
