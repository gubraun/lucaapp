import RxSwift

public class LucaScheduling {
    public static let backgroundScheduler = SerialDispatchQueueScheduler(qos: .default)
}
