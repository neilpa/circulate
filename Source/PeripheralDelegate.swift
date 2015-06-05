//
//  PeripheralDelegate.swift
//  Circulate
//
//  Created by Neil Pankey on 5/30/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa
import Box

internal struct Failable<T> {
    let value: T
    let error: NSError?

    init(_ value: T, _ error: NSError?) {
        self.value = value
        self.error = error
    }

    var event: Event<T, NSError> {
        if let error = error {
            return .Error(Box(error))
        }
        return .Next(Box(value))
    }
}

// Delegate for `CBPeripheral` exposing signals for the `CBPeripheralDelegate` methods.
internal final class PeripheralDelegate: NSObject, CBPeripheralDelegate {
    typealias PeripheralSignal = Signal<Failable<CBPeripheral>, NoError>
    typealias ServiceSignal = Signal<Failable<CBService>, NoError>
    typealias CharacteristicSignal = Signal<Failable<CBCharacteristic>, NoError>

    let serviceDiscovery: PeripheralSignal
    private let _serivceSink: PeripheralSignal.Observer

    let characteristicDiscovery: ServiceSignal
    private let _characteristicSink: ServiceSignal.Observer

    let readSignal: CharacteristicSignal
    private let _readSink: CharacteristicSignal.Observer

    let writeSignal: CharacteristicSignal
    private let _writeSink: CharacteristicSignal.Observer

    let notifySignal: CharacteristicSignal
    private let _notifySink: CharacteristicSignal.Observer

    init(_ peripheral: CBPeripheral) {
        (serviceDiscovery, _serivceSink) = PeripheralSignal.pipe()
        (characteristicDiscovery, _characteristicSink) = ServiceSignal.pipe()

        (readSignal, _readSink) = CharacteristicSignal.pipe()
        (writeSignal, _writeSink) = CharacteristicSignal.pipe()
        (notifySignal, _notifySink) = CharacteristicSignal.pipe()

        super.init()
        peripheral.delegate = self
    }

    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        sendNext(_serivceSink, Failable(peripheral, error))
    }

    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        sendNext(_characteristicSink, Failable(service, error))
    }

    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        sendNext(_readSink, Failable(characteristic, error))
    }

    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        sendNext(_writeSink, Failable(characteristic, error))
    }

    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        sendNext(_notifySink, Failable(characteristic, error))
    }
}
