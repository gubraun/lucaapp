import UIKit

class DocumentViewFactory {
    static func createView(for document: Document, with delegate: DocumentViewDelegate) -> DocumentView? {
        if document is CoronaTest {
            return CoronaTestView.createView(document: document, delegate: delegate)
        } else if document is Appointment {
            return AppointmentView.createView(document: document, delegate: delegate)
        } else if document is Vaccination {
            return CoronaVaccineItemView.createView(document: document, delegate: delegate)
        } else if document is Recovery {
            return CoronaRecoveryView.createView(document: document, delegate: delegate)
        }

        return nil
    }

    static func group(views: [DocumentView], with delegate: HorizontalDocumentListViewDelegate) -> [UIView] {

        var groupedViews: [String: [DocumentView]] = [:]
        var returnViews: [UIView] = []

        for item in views {
            if let item = item as? HorizontalGroupable & DocumentView {
                if groupedViews[item.groupedKey] == nil {
                    groupedViews[item.groupedKey] = []
                }
                groupedViews[item.groupedKey]?.append(item)
            } else {
                returnViews.append(item)
            }
        }

        for (_, group) in groupedViews {
            let horizontalItemView: HorizontalDocumentListView = HorizontalDocumentListView(views: group)
            group.forEach { $0.delegate = horizontalItemView }
            horizontalItemView.delegate = delegate
            returnViews.append(horizontalItemView)
        }

        return returnViews
    }
}
