import UIKit

class HistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var checkinLocationNameLabel: UILabel!
    @IBOutlet weak var checkinGroupNameLabel: UILabel!
    @IBOutlet weak var checkinDateLabel: UILabel!
    @IBOutlet weak var topHistoryLineView: UIView!
    @IBOutlet weak var bottomHistoryLineView: UIView!

    var infoPressedActionHandler: (() -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        checkinGroupNameLabel.isHidden = false
    }

    func setup(historyEvent: HistoryEvent) {
        infoButton.isHidden = true
        if let userEvent = historyEvent as? UserEvent {
            setupUserEvent(userEvent: userEvent)
        } else if let userUpdate = historyEvent as? UserDataUpdate {
            checkinLocationNameLabel.text = L10n.History.Data.updated
            checkinGroupNameLabel.isHidden = true
            checkinDateLabel.text = userUpdate.date.formattedDateTime
        } else if let event = historyEvent as? UserDataTransfer {
            checkinLocationNameLabel.text = L10n.History.Data.shared
            checkinGroupNameLabel.isHidden = true
            infoButton.isHidden = false
            checkinDateLabel.text = event.date.formattedDateTime
        }

        bottomHistoryLineView.isHidden = false
        topHistoryLineView.isHidden = false
    }

    func setupUserEvent(userEvent: UserEvent) {
        if let locationName = userEvent.checkin.location?.locationName {
            checkinLocationNameLabel.text = locationName
            checkinGroupNameLabel.text = userEvent.checkin.location?.groupName
        } else {
            checkinLocationNameLabel.text = userEvent.checkin.location?.groupName ?? userEvent.checkin.location?.name
            checkinGroupNameLabel.text = nil
        }

        checkinDateLabel.text = userEvent.formattingCheckinCheckoutDate()

        if let checkout = userEvent.checkout {
            checkinDateLabel.accessibilityLabel = L10n.History.Checkin.Checkout.time(userEvent.checkin.date.accessibilityDate, checkout.date.accessibilityDate)
        } else {
            checkinDateLabel.accessibilityLabel = userEvent.checkin.date.accessibilityDate
        }

        if userEvent.checkin.role == .host, let firstName = LucaPreferences.shared.firstName, let lastName = LucaPreferences.shared.lastName {
            checkinLocationNameLabel.text = "\(L10n.Private.Meeting.Info.title): \(firstName) \(lastName)"
            infoButton.isHidden = false
        }
    }

    @IBAction func infoPressed(_ sender: UIButton) {
        self.infoPressedActionHandler?()
    }

    func setupHistoryLineViews(position: TableViewPosition) {
        switch position {
        case .only:
            bottomHistoryLineView.isHidden = true
            topHistoryLineView.isHidden = true
        case .last:
            bottomHistoryLineView.isHidden = true
        case .first:
            topHistoryLineView.isHidden = true
        }
    }

}

enum TableViewPosition {

    case last
    case first
    case only

}
