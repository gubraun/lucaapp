import UIKit

class ShareHistoryPickDaysAlertViewController: UIViewController {
    @IBOutlet weak var dayPicker: UIPickerView!

    @IBOutlet weak var titleLabel: UILabel!
    private let availableDays = Array(1...14)
    private var selectedNumberOfDays: Int = 14
    private var confirmAction: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.75)

        configureSubviews()
        setupAccessibility()
    }

    func setup(confirmAction: ((Int) -> Void)?) {
        self.confirmAction = confirmAction
    }

    private func configureSubviews() {
        dayPicker.dataSource = self
        dayPicker.delegate = self
        preselectAvailableNumberOfDays()
    }

    private func preselectAvailableNumberOfDays() {
        dayPicker.selectRow(availableDays.count - 1, inComponent: 0, animated: false)
        selectedNumberOfDays = availableDays[availableDays.count - 1]
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)

    }

    @IBAction func shareHistoryButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        confirmAction?(selectedNumberOfDays)
    }
}

extension ShareHistoryPickDaysAlertViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        availableDays.count
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        pickerLabel.textColor = .black
        pickerLabel.text = "\(availableDays[row])"
        pickerLabel.font = .montserratDataAccessAlertDayPicker
        pickerLabel.textAlignment = NSTextAlignment.center

        return pickerLabel
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedNumberOfDays = availableDays[row]
    }
}

// MARK: - Accessibility
extension ShareHistoryPickDaysAlertViewController {

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header
        UIAccessibility.setFocusTo(titleLabel, notification: .layoutChanged, delay: 0.8)
    }

}
