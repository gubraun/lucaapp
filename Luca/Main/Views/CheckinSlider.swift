import UIKit

class CheckinSlider: UIControl {
    
    override var frame: CGRect {
        didSet {
            updateViews()
            layer.cornerRadius = frame.size.height / 2
        }
    }
    
    var value: CGFloat = 0 {
        didSet {
            updateViews()
        }
    }
    
    var minValue: CGFloat = 0
    var maxValue: CGFloat {
        return 1 - sliderImage.frame.size.width / frame.width
    }
    
    let sliderImage = UIImageView()
    var lastPoint = CGPoint()
  
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
  
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        layer.cornerRadius = frame.size.height / 2
        
        sliderImage.image = UIImage(named: "sliderCircleFlipped")
        addSubview(sliderImage)
    }
  
    private func updateViews() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sliderImage.frame = CGRect(origin: pointForValue(value),
                                   size: CGSize(width: frame.height, height: frame.height))
        CATransaction.commit()
    }
  
    func pointForValue(_ value: CGFloat) -> CGPoint {
        return CGPoint(x: CGFloat(frame.width) * value, y: 0)
    }

}

extension CheckinSlider {
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        lastPoint = touch.location(in: self)
    
        if sliderImage.frame.contains(lastPoint) {
            sliderImage.isHighlighted = true
        }
        return sliderImage.isHighlighted
    }
  
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)
        let deltaPoint = point.x - lastPoint.x
        let deltaValue = deltaPoint / bounds.width
    
        lastPoint = point
    
        if sliderImage.isHighlighted {
            value += deltaValue
            value = boundValue(value, lowerValue: 0,
                               upperValue: 1 - sliderImage.frame.size.width / frame.width)
        }
        sendActions(for: .valueChanged)
        return true
    }
  
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        sliderImage.isHighlighted = false
    }
  
    private func boundValue(_ value: CGFloat, lowerValue: CGFloat, upperValue: CGFloat) -> CGFloat {
        return min(max(value, lowerValue), upperValue)
    }
    
}
