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
public final class Peripheral {
    private let central: CBCentralManager
    private let peripheral: CBPeripheral
    private let delegate: PeripheralDelegate

    public var identifier: String {
        return peripheral.identifier.UUIDString
    }

    public var name: String {
        return peripheral.name ?? ""
    }

    internal init(central: CBCentralManager, peripheral: CBPeripheral) {
        self.central = central
        self.peripheral = peripheral
        delegate = PeripheralDelegate(peripheral)
    }

    deinit {
        central.cancelPeripheralConnection(peripheral)
    }

    // TODO Errors
    public func discoverServices(services: [CBUUID]?) -> SignalProducer<CBService, NoError> {
        return SignalProducer { observer, disposable in
            self.delegate.serviceSignal
                |> take(1)
                |> uncollect
                |> observe(observer)

            // TODO Do we need to do something similar to scanning and only allow
            //      one in-flight discover call at a time.
            self.peripheral.discoverServices(services)
        }
        |> logEvents("discoverServices:")
    }

    public func discoverCharacteristics(service: CBService) -> SignalProducer<CBCharacteristic, NoError> {
        return SignalProducer { observer, disposable in
            self.delegate.characteristicSignal
                |> map {
                    $0.characteristics.map { $0 as! CBCharacteristic }
                }
                |> uncollect
                |> observe(observer)

            // TODO Do we need to do something similar to scanning and only allow
            //      one in-flight discover call at a time.
            self.peripheral.discoverCharacteristics(nil, forService: service)
        }
        |> logEvents("discoverCharacteristics:")
    }

    public func notify(characteristic: CBCharacteristic) -> SignalProducer<CBCharacteristic, NoError> {
        return SignalProducer { observer, disposable in
            self.delegate.notifySignal
                |> take(1)
                |> observe(observer)

            // TODO Do we need to do something similar to scanning and only allow
            //      one in-flight call at a time.
            self.peripheral.setNotifyValue(true, forCharacteristic: characteristic)
        }
//        |> logEvents("notify:")
    }

    public func read(characteristic: CBCharacteristic) -> SignalProducer<CBCharacteristic, NoError> {
        return SignalProducer { observer, disposable in
            self.delegate.readSignal
                |> take(1)
                |> observe(observer)

            // TODO Do we need to do something similar to scanning and only allow
            //      one in-flight call at a time.
            self.peripheral.readValueForCharacteristic(characteristic)
        }
//        |> logEvents("read:")
    }

    public func write(data: NSData, characteristic: CBCharacteristic) -> SignalProducer<CBCharacteristic, NoError> {
        return SignalProducer { observer, disposable in
            self.delegate.readSignal
                |> take(1)
                |> observe(observer)

            // TODO Do we need to do something similar to scanning and only allow
            //      one in-flight call at a time.
            self.peripheral.writeValue(data, forCharacteristic: characteristic, type: .WithoutResponse)
        }
//        |> logEvents("write:")
    }
}

