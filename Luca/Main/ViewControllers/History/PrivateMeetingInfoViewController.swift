import UIKit

class PrivateMeetingInfoViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var guestListTextView: UITextView!

    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewHeightMultiplier: NSLayoutConstraint!

    var guestListText = ""
    var historyEvent: HistoryEvent!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let firstName = LucaPreferences.shared.firstName, let lastName = LucaPreferences.shared.lastName {
            titleLabel.text = "\(firstName) \(lastName)"
        }

        if let event = historyEvent as? UserEvent, let checkout = event.checkout {
            dateLabel.text = "\(event.checkin.date.formattedDateTime) - \(checkout.date.formattedDateTime)"
            dateLabel.accessibilityLabel = "\(event.checkin.date.accessibilityDate) - \(checkout.date.accessibilityDate)"
            setup(entry: checkout)
        } else if let event = historyEvent as? UserEvent {
            dateLabel.text = event.checkin.date.formattedDateTime
            dateLabel.accessibilityLabel = "\(event.checkin.date.accessibilityDate)"
            setup(entry: event.checkin)
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIAccessibility.setFocusTo(titleLabel, notification: .layoutChanged)
    }

    func setup(entry: HistoryEntry) {
        let uniqueGuestList = Set(entry.guestlist ?? [])

        for (index, guest) in uniqueGuestList.enumerated() {
            guestListText.append("\(index + 1)    \(guest)\n")
        }

        guestListTextView.text = uniqueGuestList.isEmpty ? L10n.Private.Meeting.Participants.none : guestListText
        adjustSizeAndScroll()
    }

    @IBAction func okButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    func adjustSizeAndScroll() {
        guestListTextView.sizeToFit()

        // Increase textView to max height, when max height is reached enable scroll.
        let contentHeight = guestListTextView.contentSize.height
        let maxHeight = view.frame.height * textViewHeightMultiplier.multiplier
        guestListTextView.isScrollEnabled = contentHeight >= maxHeight
        textViewHeight.constant = contentHeight >= maxHeight ? maxHeight : contentHeight
    }

    @IBAction func viewPressed(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

}
