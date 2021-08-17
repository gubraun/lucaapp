import UIKit

protocol DocumentViewDelegate: AnyObject {
    func didToggleView()
    func didTapDelete(for document: Document)
}

protocol DocumentViewProtocol: AnyObject {
    var isExpanded: Bool { get set }
    func toggleView(animated: Bool)
    static func createView(document: Document, delegate: DocumentViewDelegate?) -> DocumentView?
}

class DocumentView: UIView {
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint?
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint?

    weak var delegate: DocumentViewDelegate?
    var position: HorizontalDocumentListViewItemPosition = .middle {
        didSet {
            updatePosition()
        }
    }

    func updatePosition() {
        if position == .leading {
            leadingConstraint?.constant = 32
            trailingConstraint?.constant = 0
        } else if position == .trailing {
            leadingConstraint?.constant = 0
            trailingConstraint?.constant = -32
        } else if position == .single {
            leadingConstraint?.constant = 32
            trailingConstraint?.constant = -32
        } else if position == .middle {
            leadingConstraint?.constant = 0
            trailingConstraint?.constant = 0
        }
    }
}
