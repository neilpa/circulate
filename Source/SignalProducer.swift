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

public func liftSignal<T, E>(signal: Signal<T, E>) -> SignalProducer<T, E> {
    return SignalProducer { observer, disposable in
        disposable.addDisposable(signal.observe(observer))
    }
}