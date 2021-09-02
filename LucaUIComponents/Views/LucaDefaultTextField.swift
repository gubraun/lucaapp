import UIKit

open class LucaDefaultTextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    open override func prepareForInterfaceBuilder() {
        self.setup()
    }

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    func setup() {
        borderStyle = .none
        layer.borderWidth = 1
        layer.cornerRadius = 8
        clearButtonMode = .whileEditing
    }
}
