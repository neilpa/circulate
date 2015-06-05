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

    public func discoverServices(uuids: [CBUUID]?) -> SignalProducer<CBService, NSError> {
        return SignalProducer { observer, disposable in
            self.delegate.serviceDiscovery
                |> take(1)
                |> map { return $0.event }
                |> dematerialize
                |> map { $0.services.map { $0 as! CBService } }
                |> uncollect
                |> observe(observer)

            // TODO Do we need to do something similar to scanning and only allow one in-flight call at a time.
            self.peripheral.discoverServices(uuids)
        }
        |> logEvents("discoverServices:")
    }

    public func discoverCharacteristics(uuids: [CBUUID]?, service: CBService) -> SignalProducer<CBCharacteristic, NSError> {
        return SignalProducer { observer, disposable in
            self.delegate.characteristicDiscovery
                |> filter { $0.value == service }
                |> take(1)
                |> map { return $0.event }
                |> dematerialize
                |> map { $0.characteristics.map { $0 as! CBCharacteristic } }
                |> uncollect
                |> observe(observer)

            // TODO Do we need to do something similar to scanning and only allow one in-flight call at a time.
            self.peripheral.discoverCharacteristics(uuids, forService: service)
        }
        |> logEvents("discoverCharacteristics:")
    }

    public func setNotifyValue(notify: Bool, characteristic: CBCharacteristic) -> SignalProducer<CBCharacteristic, NSError> {
        return SignalProducer { observer, disposable in
            self.delegate.notifySignal
                |> filter { $0.value == characteristic }
                |> take(1)
                |> map { return $0.event }
                |> dematerialize
                |> observe(observer)

            self.peripheral.setNotifyValue(notify, forCharacteristic: characteristic)
        }
        |> logEvents("subscribe:")
    }

    public func read(characteristic: CBCharacteristic) -> SignalProducer<CBCharacteristic, NSError> {
        return SignalProducer { observer, disposable in
            self.delegate.readSignal
                |> filter { $0.value == characteristic }
                |> take(1)
                |> map { return $0.event }
                |> dematerialize
                |> observe(observer)

            self.peripheral.readValueForCharacteristic(characteristic)
        }
        |> logEvents("read:")
    }

    public func write(data: NSData, characteristic: CBCharacteristic, type: CBCharacteristicWriteType) -> SignalProducer<CBCharacteristic, NSError> {
        return SignalProducer { observer, disposable in
            self.delegate.writeSignal
                |> filter { $0.value == characteristic }
                |> take(1)
                |> map { return $0.event }
                |> dematerialize
                |> observe(observer)

            self.peripheral.writeValue(data, forCharacteristic: characteristic, type: type)
        }
        |> logEvents("write:")
    }

    /// This is a write/read hybrid to support devices that treat characteristics as a command pipe. That is,
    /// commands are written to the characteristic with results returned as updates rather than write responses.
    public func execute(data: NSData, characteristic: CBCharacteristic) -> SignalProducer<CBCharacteristic, NSError> {
        return SignalProducer { observer, disposable in
            self.delegate.readSignal
                |> filter { $0.value == characteristic }
                |> take(1)
                |> map { return $0.event }
                |> dematerialize
                |> observe(observer)

            self.peripheral.writeValue(data, forCharacteristic: characteristic, type: .WithoutResponse)
        }
        |> logEvents("execute:")
    }
}

