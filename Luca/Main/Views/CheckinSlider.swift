import UIKit
import RxSwift

class CheckinSlider: UIControl {
    let valueObservable: BehaviorSubject<CGFloat> = BehaviorSubject(value: 0)
    let completed: PublishSubject<Bool> = PublishSubject()

    override var frame: CGRect {
        didSet {
            layer.cornerRadius = frame.size.height / 2
        }
    }

    let minValue = CGFloat(0)
    let maxValue = CGFloat(1)
    private var maxXPos: CGFloat {
        frame.width - frame.height
    }

    private var value: CGFloat {
        sliderImage.frame.origin.x / maxXPos
    }

    let sliderImage = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func reset() {
        setSliderFrame(x: maxXPos)
    }

    private func setup() {
        layer.cornerRadius = frame.size.height / 2
        layer.borderColor = UIColor.black.cgColor
        sliderImage.image = UIImage(named: "arrowCircle")
        addSubview(sliderImage)
        reset()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView))
        sliderImage.isUserInteractionEnabled = true
        sliderImage.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedView(_:)))
        sliderImage.addGestureRecognizer(tapGesture)
        
        sliderImage.accessibilityLabel = L10n.LocationCheckinViewController.Accessibility.checkoutSlider
        sliderImage.isAccessibilityElement = true
        sliderImage.accessibilityTraits = [.allowsDirectInteraction]
    }
    
    @objc func tappedView(_ gesture: UITapGestureRecognizer) {
        guard sliderImage.accessibilityElementIsFocused() && UIAccessibility.isVoiceOverRunning else { return }
        self.completed.onNext(true)
    }

    @objc func draggedView(_ gesture: UIPanGestureRecognizer) {
        if UIAccessibility.isVoiceOverRunning {
            return
        }
        let translation = gesture.translation(in: self)
        let xToComplete = maxXPos * 0.2

        if gesture.state == .began {
            reset()
        } else if gesture.state == .changed {
            let newXValue = maxXPos + translation.x
            let newWithinBounds = boundValue(newXValue, lowerValue: minValue, upperValue: maxXPos)
            setSliderFrame(x: newWithinBounds)
            valueObservable.onNext(value)

            if value == minValue {
                completed.onNext(true)
            }
        } else if gesture.state == .ended {
            let finalX = sliderImage.frame.origin.x < xToComplete ? minValue : maxXPos
            UIView.animate(withDuration: 0.1) {
                self.setSliderFrame(x: finalX)
                self.completed.onNext(self.value == self.minValue)
            }
        }
    }

    private func setSliderFrame(x: CGFloat) {
        sliderImage.frame = CGRect(origin: CGPoint(x: x, y: 0),
                                   size: CGSize(width: frame.height, height: frame.height))
    }

    private func boundValue(_ value: CGFloat, lowerValue: CGFloat, upperValue: CGFloat) -> CGFloat {
        return min(max(value, lowerValue), upperValue)
    }
}
