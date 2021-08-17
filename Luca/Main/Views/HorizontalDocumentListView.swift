import UIKit

protocol HorizontalDocumentListViewDelegate: AnyObject {
    func didTapDelete(for document: Document)
}

protocol HorizontalGroupable {
    var groupedKey: String { get }
}

enum HorizontalDocumentListViewItemPosition {
    case leading
    case middle
    case trailing
    case single
}

class HorizontalDocumentListView: UIView {
    weak var delegate: HorizontalDocumentListViewDelegate?

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.delegate = self

        return scrollView
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 16

        return stackView
    }()

    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.isUserInteractionEnabled = false

        return pageControl
    }()

    var heightConstraint: NSLayoutConstraint?
    var isExpanded: Bool = false

    var vaccinationList: [Vaccination]? {
        didSet {
            setupStackView()
        }
    }

    var documentViewList: [DocumentView]? {
        didSet {
            setupStackView()
        }
    }

    init(views: [DocumentView]) {
        super.init(frame: CGRect.zero)

        setupUI()
        setupConstraints()

        documentViewList = views
        setupStackView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateScrolViewHeight()
    }
}

extension HorizontalDocumentListView {
    private func setupUI() {
        clipsToBounds = true
        backgroundColor = .clear

        heightConstraint = self.scrollView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.priority = UILayoutPriority(999)
        heightConstraint?.isActive = true

        addSubview(scrollView)
        addSubview(pageControl)
        scrollView.addSubview(stackView)
    }

    private func updateScrolViewHeight() {
        DispatchQueue.main.async {
            let height = self.stackView.arrangedSubviews.map {$0.frame.size.height}.max() ?? 0.0

            // Here we hack the height of the scrollView to get a nive
            // expand / collape animation
            // when the view got collapsed, we delay the change of the
            // heightConstraint
            if height < 200 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.heightConstraint?.constant = height
                }

            } else {
                self.heightConstraint?.constant = height
            }
        }
    }

    private func setupStackView() {
        stackView.removeAllArrangedSubviews()

        guard let documentViewList = documentViewList else { return }

        for (index, item) in documentViewList.enumerated() {
            let view = item
            let position: HorizontalDocumentListViewItemPosition = documentViewList.count == 1 ? .single : index == 0 ? .leading : index == documentViewList.count - 1 ? .trailing : .middle
            view.position = position

            var width = UIScreen.main.bounds.size.width
            if position != .single {
                width -= 32
            }
            let anchor = view.widthAnchor.constraint(equalToConstant: width)
            anchor.priority = UILayoutPriority(999)
            anchor.isActive = true
            stackView.addArrangedSubview(view)
        }

        pageControl.isHidden = documentViewList.count == 1
        pageControl.numberOfPages = documentViewList.count
        updateScrolViewHeight()
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: 0).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0).isActive = true
        stackView.heightAnchor.isEqual(scrollView.heightAnchor)

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
    }
}

extension HorizontalDocumentListView: DocumentViewDelegate {
    func didToggleView() {
        updateScrolViewHeight()
    }

    func didTapDelete(for document: Document) {
        delegate?.didTapDelete(for: document)
    }
}

extension HorizontalDocumentListView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = scrollView.contentOffset.x / (scrollView.frame.size.width - 64)
        pageControl.currentPage = Int(pageNumber)
    }
}
