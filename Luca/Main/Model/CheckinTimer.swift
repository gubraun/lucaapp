import Foundation

public class CheckinTimer {

    static let shared = CheckinTimer()

    weak var delegate: TimerDelegate?

    private(set) var isPlaying = false
    private(set) var begin: Date?

    private var timer: Timer? = nil {
        willSet {
            timer?.invalidate()
        }
    }
    var counter: Double {
        if let date = begin {
            return Date().timeIntervalSince1970 - date.timeIntervalSince1970
        }
        return 0.0
    }

    func start(from date: Date?) {
        if isPlaying {
            return
        }
        begin = date
        if begin == nil {
            begin = Date()
        }
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        isPlaying = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        begin = nil
    }

    @objc func timerAction() {
        delegate?.timerDidTick()
    }

}
