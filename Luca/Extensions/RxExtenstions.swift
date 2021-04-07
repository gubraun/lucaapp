import Foundation
import RxSwift
import RxCocoa

/// It enables debug prints in `toggleableDebug`
let debugPrintsEnabled = false

public enum CommonRxError: Error {
    case selfDoesNotExistAnymore
    case unexpectedNil
}

public extension Completable {
    
    static func zip(_ stream: Observable<Completable>) -> Completable {
        return stream
            .toArray()
            .asObservable()
            .flatMap { Completable.zip($0) }
            .asCompletable()
    }
    
    static func from(_ closure: @escaping () throws -> Void) -> Completable {
        return Completable.deferred {
            do {
                try closure()
                return Completable.empty()
            }
            catch {
                return Completable.error(error)
            }
        }
    }
    
    func onErrorComplete() -> Completable {
        return self
            .asObservable()
            .onErrorComplete()
            .asCompletable()
    }
    
    func debug(logUtil: LogUtil, _ identifier: String) -> Completable {
        return self.do(onError: {error in
            logUtil.log("[\(identifier)] error: \(error)", entryType: .info)
        }, onCompleted: {
            logUtil.log("[\(identifier)] completed", entryType: .info)
        }, onSubscribe: {
            logUtil.log("[\(identifier)] subscribe", entryType: .info)
        }, onSubscribed: {
            logUtil.log("[\(identifier)] after subscribe", entryType: .info)
        }, onDispose: {
            logUtil.log("[\(identifier)] disposed", entryType: .info)
        })
    }
    
    func logError(_ logUtil: LogUtil, _ identifier: String = "") -> Completable {
        self.do(onError: { error in
            if identifier != "" {
                logUtil.log("[\(identifier)] error: \(error)", entryType: .error)
            } else {
                logUtil.log("\(error)", entryType: .error)
            }
        })
    }
    
}

public enum ObservableError: Error {
    
    /// Occures when the value in the .cast() operator couldn't be casted
    case casting(from: String, to: String)
    
}

public protocol OptionalType {
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    /// Cast `Optional<Wrapped>` to `Wrapped?`
    public var value: Wrapped? {
        return self
    }
}

public extension ObservableType where Element: OptionalType {
    
    func unwrapOptional(errorOnNil: Bool = false) -> Observable<Element.Wrapped> {
        self.filter { (value) in
            if value.value == nil {
                if errorOnNil {
                    throw NSError(domain: "Nil force unwrapped!", code: 404, userInfo: nil)
                }
                return false
            }
            return true
        }
        .map { $0.value! }
    }
}

public extension PrimitiveSequence where Trait == SingleTrait, Element: OptionalType {
    
    func unwrapOptional(errorOnNil: Bool = false) -> Single<Element.Wrapped> {
        self.filter { (value) in
            if value.value == nil {
                if errorOnNil {
                    throw NSError(domain: "Nil force unwrapped!", code: 404, userInfo: nil)
                }
                return false
            }
            return true
        }
        .map { $0.value! }
        .asObservable()
        .asSingle()
    }
}

public extension PrimitiveSequence where Trait == MaybeTrait, Element: OptionalType {
    
    func unwrapOptional(errorOnNil: Bool = false) -> Maybe<Element.Wrapped> {
        self.filter { (value) in
            if value.value == nil {
                if errorOnNil {
                    throw NSError(domain: "Nil force unwrapped!", code: 404, userInfo: nil)
                }
                return false
            }
            return true
        }
        .map { $0.value! }
    }
}

public extension ObservableType {
    
    func retry(maxAttempts: Int, delay: RxTimeInterval, scheduler: SchedulerType) -> Observable<Element> {
        return self.retryWhen { errors in
            return errors.enumerated().flatMap { (index, error) -> Observable<Int64> in
                if index <= maxAttempts {
                    return Observable<Int64>.timer(delay, scheduler: scheduler)
                } else {
                    return Observable.error(error)
                }
            }
        }
    }
    
    func retry(delay: RxTimeInterval, scheduler: SchedulerType) -> Observable<Element> {
        return self.retryWhen { errors in
            return errors.enumerated().flatMap { (index, error) -> Observable<Int64> in
                return Observable<Int64>.timer(delay, scheduler: scheduler)
            }
        }
    }
    
    func onErrorComplete() -> Observable<Element> {
        return self
            .materialize()
            .map { event -> Event<Element> in
                if case Event.error(_) = event {
                    return Event<Element>.completed
                }
                return event
            }
            .dematerialize()
    }
    
    func cast<T>() -> Observable<T> {
        return self.map { (value) in
            if let retVal = value as? T {
                return retVal
            }
            throw ObservableError.casting(from: String(reflecting: Element.self), to: String(reflecting: T.self))
        }
    }
    
    func cast<T>(_ type: T.Type) -> Observable<T> {
        return self.map { (value) in
            if let retVal = value as? T {
                return retVal
            }
            throw ObservableError.casting(from: String(reflecting: Element.self), to: String(reflecting: T.self))
        }
    }
    
    static func count(_ source: Observable<Element>, predicate: @escaping ((Element) -> Bool)) -> Single<Int> {
        return source
            .reduce(0) { (cumulated, value) -> Int in
                if predicate(value) {
                    return cumulated + 1
                }
                return cumulated
            }
            .take(1)
            .asSingle()
    }
    
    func count(_ predicate: @escaping ((Element) -> Bool)) -> Single<Int> {
        return Observable<Element>.count(self.asObservable(), predicate: predicate)
    }
    
    static func select(_ source: Observable<Element>, comparator: @escaping ((Element, Element)->Bool)) -> Single<Element> {
        var currentVal: Element? = nil
        return source
            .materialize()
            .flatMap { (event) -> Observable<Event<Element>> in
                
                if event.isCompleted { //If its completed, return the current value or generate an error if the currentVal is not yet obtained
                    if let min = currentVal {
                        return Observable<Event<Element>>.from([Event<Element>.next(min), Event<Element>.completed])
                    }
                    return Observable<Event<Element>>.just(Event<Element>.error(RxError.noElements))
                } else if let element = event.element { //If this has an element, check if the comparator returns true and set this value
                    if currentVal == nil || comparator(element, currentVal!) {
                        currentVal = element
                    }
                } else if event.error != nil { //If it's an error, send it along down the stream
                    return Observable<Event<Element>>.just(Event<Element>.error(event.error!))
                }
                return Observable<Event<Element>>.never()
                
            }
            .dematerialize()
        .asSingle()
        .do(onDispose: {
            currentVal = nil
        })
    }
    
    func select(comparator: @escaping ((Element, Element)->Bool)) -> Single<Element> {
        return Observable.select(self.asObservable(), comparator: comparator)
    }
    
    func toggleableDebug(_ identifier: String? = nil, trimOutput: Bool = false) -> Observable<Element> {
        if debugPrintsEnabled {
            return self.debug(identifier, trimOutput: trimOutput).asObservable()
        }
        return self.asObservable()
    }
    
    func debugDepth(_ identifier: String) -> Observable<Element> {
        var depth = 0
        return self
            .do(onSubscribe: {
                if depth == 0 {
                    depth += 1
                    print("\(identifier) \(depth) - first")
                } else {
                    depth += 1
                    print("\(identifier) \(depth)")
                }
                }, onDispose: {
                    depth -= 1
                    if depth == 0 {
                        print("\(identifier) \(depth) - last")
                    } else {
                        print("\(identifier) \(depth)")
                    }
            })
    }
    
    /// Filters elements by a deferred filter
    func deferredFilter(_ filter: @escaping ((Element) -> Single<Bool>)) -> Observable<Element> {
        return self.flatMap { (element: Element) in
            return filter(element)
                .flatMap { Single.just((element, $0)) }
        }
        .filter { $0.1 }
        .map { $0.0 }
    }
}

public extension ObservableType where Element: Comparable {
    
    static func min(_ source: Observable<Element>) -> Single<Element> {
        return select(source, comparator: { $0 < $1 })
    }
    
    static func max(_ source: Observable<Element>) -> Single<Element> {
        return select(source, comparator: { $0 > $1 })
    }
    
    func min() -> Single<Element> {
        return Observable.min(self.asObservable())
    }
    
    func max() -> Single<Element> {
        return Observable.max(self.asObservable())
    }
    
}

public extension PrimitiveSequenceType where Trait == SingleTrait {
    
    static func from(_ closure: @escaping () throws -> Element) -> Single<Element> {
        return Single<Element>.deferred {
            do {
                let retVal = try closure()
                return Single.just(retVal)
            }
            catch {
                return Single.error(error)
            }
        }
    }
    
    func cast<T>() -> Single<T> {
        return self.map { (value) in
            if let retVal = value as? T {
                return retVal
            }
            throw ObservableError.casting(from: String(reflecting: Element.self), to: String(reflecting: T.self))
        }
    }
    
    func logError(_ logUtil: LogUtil, _ identifier: String = "") -> Single<Element> {
        self.do(onError: { error in
            if identifier != "" {
                logUtil.log("[\(identifier)] error: \(error)", entryType: .error)
            } else {
                logUtil.log("\(error)", entryType: .error)
            }
        })
    }
    
    func debug(logUtil: LogUtil, _ identifier: String) -> Single<Element> {
        return self.do(onSuccess: {
            logUtil.log("[\(identifier)] success: \($0)", entryType: .info)
        }, onError: {error in
            logUtil.log("[\(identifier)] error: \(error)", entryType: .info)
        }, onSubscribe: {
            logUtil.log("[\(identifier)] subscribe", entryType: .info)
        }, onSubscribed: {
            logUtil.log("[\(identifier)] after subscribe", entryType: .info)
        }, onDispose: {
            logUtil.log("[\(identifier)] disposed", entryType: .info)
        })
    }
    
}

public extension PrimitiveSequenceType where Trait == MaybeTrait {
    
    static func from(_ closure: @escaping () throws -> Element?) -> Maybe<Element> {
        return Maybe<Element>.deferred {
            do {
                let retVal = try closure()
                if let retValUnwrapped = retVal {
                    return Maybe.just(retValUnwrapped)
                }
                return Maybe.empty()
            }
            catch {
                return Maybe.error(error)
            }
        }
    }
    
    func cast<T>() -> Maybe<T> {
        return self.map { (value) in
            if let retVal = value as? T {
                return retVal
            }
            throw ObservableError.casting(from: String(reflecting: Element.self), to: String(reflecting: T.self))
        }
    }
    
    func logError(_ logUtil: LogUtil, _ identifier: String = "") -> Maybe<Element> {
        self.do(onError: { error in
            if identifier != "" {
                logUtil.log("[\(identifier)] error: \(error)", entryType: .error)
            } else {
                logUtil.log("\(error)", entryType: .error)
            }
        })
    }
    
}

public extension PrimitiveSequence {
    func retry(maxAttempts: Int, delay: RxTimeInterval, scheduler: SchedulerType) -> PrimitiveSequence<Trait, Element> {
        return self.retryWhen { errors in
            return errors.enumerated().flatMap { (index, error) -> Observable<Int64> in
                if index <= maxAttempts {
                    return Observable<Int64>.timer(delay, scheduler: scheduler)
                } else {
                    return Observable.error(error)
                }
            }
        }
    }
    
    func retry(delay: RxTimeInterval, scheduler: SchedulerType) -> PrimitiveSequence<Trait, Element> {
        return self.retryWhen { errors in
            return errors.enumerated().flatMap { (index, error) -> Observable<Int64> in
                return Observable<Int64>.timer(delay, scheduler: scheduler)
            }
        }
    }
    
    func toggleableDebug(_ identifier: String? = nil, trimOutput: Bool = false) -> Self {
        if debugPrintsEnabled {
            return self.debug(identifier, trimOutput: trimOutput)
        }
        return self
    }
}

public extension ObservableType {
    func debug(logUtil: LogUtil, _ identifier: String) -> Observable<Self.Element> {
        return self.do(onNext: { element in
            logUtil.log("[\(identifier)] next: \(element)", entryType: .info)
        }, onError: {error in
            logUtil.log("[\(identifier)] error: \(error)", entryType: .info)
        }, onCompleted: {
            logUtil.log("[\(identifier)] completed", entryType: .info)
        }, onSubscribe: {
            logUtil.log("[\(identifier)] subscribe", entryType: .info)
        }, onSubscribed: {
            logUtil.log("[\(identifier)] after subscribe", entryType: .info)
        }, onDispose: {
            logUtil.log("[\(identifier)] disposed", entryType: .info)
        })
    }
    
    func logError(_ logUtil: LogUtil, _ identifier: String = "") -> Observable<Self.Element> {
        self.do(onError: { error in
            if identifier != "" {
                logUtil.log("[\(identifier)] error: \(error)", entryType: .error)
            } else {
                logUtil.log("\(error)", entryType: .error)
            }
        })
    }
}

// Two way binding operator between control property and relay, that's all it takes.
infix operator <-> : DefaultPrecedence

func <-> <T> (property: ControlProperty<T>, relay: BehaviorRelay<T>) -> Disposable {
    let bindToUIDisposable = relay.bind(to: property)
    let bindToRelay = property
        .subscribe(onNext: { n in
            relay.accept(n)
        }, onCompleted:  {
            bindToUIDisposable.dispose()
        })

    return Disposables.create(bindToUIDisposable, bindToRelay)
}
