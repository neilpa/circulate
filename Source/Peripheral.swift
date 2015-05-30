//
//  Peripheral.swift
//  Circulate
//
//  Created by Neil Pankey on 5/29/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa
import Rex

// Wraps a `CBPeripheral` exposing a RAC-compatible interface.
public final class Peripheral: NSObject, CBPeripheralDelegate {
    private let proxy: PeripheralProxy

    public var identifier: String {
        return proxy.identifier
    }

    public var name: String {
        return proxy.name
    }

    public init(_ peripheral: CBPeripheral) {
        proxy = PeripheralProxy(peripheral)
    }

    public func discoverServices(services: [CBUUID]) -> SignalProducer<CBService, NSError> {
        let services: [CBUUID]? = services.isEmpty ? nil : services
        return SignalProducer { observer, disposable in
            self.proxy.serviceSignal
                |> take(1)
                |> uncollect
                |> observe(observer)

            // TODO Do we need to do something similar to scanning and only allow
            //      one in-flight discover call at a time.
            self.proxy.discoverServices(services)
        }
        |> on(started: { println("STARTED") }, event: println, disposed: { println("DISPOSED") })
    }
}

