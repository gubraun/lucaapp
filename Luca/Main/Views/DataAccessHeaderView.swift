import UIKit

class DataAccessHeaderView: UITableViewHeaderFooterView {

    let departmentLabel = UILabel()
    let bulletPointView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureContents()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configureContents() {
        contentView.backgroundColor = .black
        departmentLabel.translatesAutoresizingMaskIntoConstraints = false
        bulletPointView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(departmentLabel)
        contentView.addSubview(bulletPointView)

        bulletPointView.backgroundColor = .white
        bulletPointView.layer.cornerRadius = 4
        bulletPointView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        bulletPointView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        bulletPointView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        bulletPointView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true

        departmentLabel.font = UIFont.montserratTableViewTitle
        departmentLabel.textColor = .white
        departmentLabel.leadingAnchor.constraint(equalTo: bulletPointView.trailingAnchor, constant: 16).isActive = true
        departmentLabel.centerYAnchor.constraint(equalTo: bulletPointView.centerYAnchor).isActive = true
    }

}
