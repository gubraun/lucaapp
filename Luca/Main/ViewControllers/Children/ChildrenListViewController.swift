import UIKit
import LucaUIComponents
import RxSwift

class ChildrenListViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addChildButton: LightStandardButton!
    @IBOutlet weak var descriptionLabel: Luca14PtLabel!

    var persons: [Person] = []

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        reloadData()
    }
}

// MARK: - Private functions

extension ChildrenListViewController {
    private func setup() {
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChildrenListCell")
        tableView.delegate = self
        tableView.dataSource = self

        title = L10n.Children.List.title
        updateDescriptionLabel()

        addChildButton.setTitle(L10n.Children.List.Add.button.uppercased(), for: .normal)
        addChildButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
    }

    private func updateDescriptionLabel() {
        descriptionLabel.text = persons.count == 0 ? L10n.Children.List.emptyDescription : L10n.Children.List.description
    }

    private func reloadData() {
        _ = ServiceContainer.shared.personService
            .retrieve { _ in
                return true
            }
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { entries in
                self.persons = entries
                self.tableView.reloadData()
                self.updateDescriptionLabel()
            })
            .subscribe()
    }

    private func delete(person: Person, completion: @escaping (Bool) -> Void) {
        _ = ServiceContainer.shared.personService
            .remove(person: person)
            .observe(on: MainScheduler.instance)
            .do(onError: { _ in
                completion(false)
            }, onCompleted: {
                completion(true)
            })
            .subscribe()
    }
}

// MARK: - Actions

extension ChildrenListViewController {
    @objc
    func didTapAdd() {
        let viewController = ViewControllerFactory.Children.createChildrenCreateViewController(delegate: self)
        present(viewController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate / UITableViewDataSource

extension ChildrenListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        persons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "ChildrenListCell", for: indexPath)

        let person = persons[indexPath.row]
        cell.selectionStyle = .none
        cell.textLabel?.font = FontFamily.Montserrat.bold.font(size: 16)
        cell.textLabel?.text = person.fullName

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            UIAlertController(
                title: L10n.Children.List.Delete.title,
                message: L10n.Children.List.Delete.message,
                preferredStyle: .alert
            )
            .actionAndCancelAlert(actionText: L10n.Navigation.Basic.confirm, action: {
                self.delete(person: self.persons[indexPath.row]) { success in
                    if success {
                        self.persons.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }, viewController: self)

        }
    }
}

// MARK: - ChildrenCreateViewControllerDelegate

extension ChildrenListViewController: ChildrenCreateViewControllerDelegate {
    func didAddPerson() {
        reloadData()
    }
}
