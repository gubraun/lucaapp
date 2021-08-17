import UIKit

@IBDesignable
class BlackButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width, height: 48.0)
    }

    private func setup() {
        self.titleLabel?.font = UIFont(name: "Montserrat-Bold", size: 14.0)
        self.setTitleColor(.white, for: .normal)
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = frame.height * 0.5
    }
}
