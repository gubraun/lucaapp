import UIKit
import LucaUIComponents
import RxSwift

protocol ChildrenCreateViewControllerDelegate: AnyObject {
    func didAddPerson()
}

class ChildrenCreateViewController: UIViewController, LucaModalAppearence {

    // MARK: - Outlets

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var saveButton: LightStandardButton!
    @IBOutlet weak var titleLabel: Luca20PtBoldLabel!
    @IBOutlet weak var descriptionLabel: Luca14PtLabel!
    @IBOutlet weak var firstnameTextField: LucaDefaultTextField!
    @IBOutlet weak var lastnameTextField: LucaDefaultTextField!

    weak var delegate: ChildrenCreateViewControllerDelegate?

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

// MARK: - Private functions

extension ChildrenCreateViewController {
    private func setup() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Navigation.Basic.cancel, style: .plain, target: self, action: #selector(cancelTapped))

        stackView.spacing = 20

        titleLabel.text = L10n.Children.Add.title
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center

        descriptionLabel.text = L10n.Children.Add.description
        descriptionLabel.numberOfLines = 0

        firstnameTextField.placeholder = L10n.Children.Add.Placeholder.firstname
        lastnameTextField.placeholder = L10n.Children.Add.Placeholder.lastname

        saveButton.setTitle(L10n.Children.Add.button.uppercased(), for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        applyColors()
    }

    private func savePerson(firstName: String, lastname: String) {
        _ = ServiceContainer.shared.personService
            .create(firstName: firstName, lastName: lastname)
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { _ in
                self.dismiss(animated: true, completion: nil)
                self.delegate?.didAddPerson()
            })
            .subscribe()
    }
}

// MARK: - Actions

extension ChildrenCreateViewController {
    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func saveTapped() {
        guard let firstname = firstnameTextField.text, let lastname = lastnameTextField.text else { return }
        guard firstname.removeWhitespaces().count > 0, lastname.removeWhitespaces().count > 0 else { return }

        savePerson(firstName: firstname, lastname: lastname)
    }
}
