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
        }, disposed: {
            println("\(prefix) DISPOSED")
        })
}
