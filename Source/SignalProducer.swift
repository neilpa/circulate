//
//  Signal.swift
//  Circulate
//
//  Created by Neil Pankey on 6/1/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import ReactiveCocoa

public func logEvents<T, E>(prefix: String)(producer: SignalProducer<T, E>) -> SignalProducer<T, E> {
    return producer
        |> on(started: {
            println("\(prefix) STARTED")
        }, event: { event in
            println("\(prefix) \(event)")
        })
}

public func serialize<T, U, E>(transform: T -> SignalProducer<U, E>) -> (Signal<(T, Signal<U, E>.Observer), E>.Observer, Disposable) {
    let (producer, sink) = SignalProducer<(T, Signal<U, E>.Observer), E>.buffer()
    let queue = producer
        |> flatMap(.Concat) { input, observer in
            return transform(input) |> on(event: { observer.put($0) })
        }
    return (sink, queue |> start())
}

public func merge<T, E> (signals: Signal<T, E>...) -> Signal<T, E> {
    return Signal { observer in
        signals.reduce(CompositeDisposable()) { disposable, signal in
            disposable += signal.observe(observer)
            return disposable
        }
    }
}

public func flatMap<T, U, E>(strategy: FlattenStrategy, #placeholder: U, transform: T -> SignalProducer<U, E>) -> SignalProducer<T?, E> -> SignalProducer<U, E> {
    return { producer in
        return producer |> flatMap(strategy) {
            $0.map(transform) ?? SignalProducer(value: placeholder)
        }
    }
}

public func ignoreError<T, E>(value: T) -> SignalProducer<T, E> -> SignalProducer<T, NoError> {
    return { producer in
        return producer |> catch { _ in SignalProducer(value: value) }
    }
}


public func liftSignal<T, E>(signal: Signal<T, E>) -> SignalProducer<T, E> {
    return SignalProducer { observer, disposable in
        disposable.addDisposable(signal.observe(observer))
    }
}
