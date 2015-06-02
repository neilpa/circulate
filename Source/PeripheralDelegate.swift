//
//  PeripheralDelegate.swift
//  Circulate
//
//  Created by Neil Pankey on 5/30/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

// Delegate for `CBPeripheral` exposing signals for the `CBPeripheralDelegate` methods.
internal final class PeripheralDelegate: NSObject, CBPeripheralDelegate {
    // TODO Make this a property?
    let nameSignal: Signal<String, NoError>
    private let _nameSink: Signal<String, NoError>.Observer

    let serviceSignal: Signal<[CBService], NoError>
    private let _serivceSink: Signal<[CBService], NoError>.Observer

    let characteristicSignal: Signal<CBService, NoError>
    private let _characteristicSink: Signal<CBService, NoError>.Observer

    let readSignal: Signal<CBCharacteristic, NoError>
    private let _readSink: Signal<CBCharacteristic, NoError>.Observer

    let writeSignal: Signal<CBCharacteristic, NoError>
    private let _writeSink: Signal<CBCharacteristic, NoError>.Observer

    let notifySignal: Signal<CBCharacteristic, NoError>
    private let _notifySink: Signal<CBCharacteristic, NoError>.Observer

    init(_ peripheral: CBPeripheral) {
        (nameSignal, _nameSink) = Signal<String, NoError>.pipe()
        (serviceSignal, _serivceSink) = Signal<[CBService], NoError>.pipe()
        (characteristicSignal, _characteristicSink) = Signal<CBService, NoError>.pipe()

        (readSignal, _readSink) = Signal<CBCharacteristic, NoError>.pipe()
        (writeSignal, _writeSink) = Signal<CBCharacteristic, NoError>.pipe()
        (notifySignal, _notifySink) = Signal<CBCharacteristic, NoError>.pipe()

        super.init()
        peripheral.delegate = self
    }

    func peripheralDidUpdateName(peripheral: CBPeripheral!) {
        sendNext(_nameSink, peripheral.name ?? "")
    }

    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        println("\(peripheral) \(error)")
        sendNext(_serivceSink, peripheral.services.map { $0 as! CBService })
    }

    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        sendNext(_characteristicSink, service)
    }

    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        sendNext(_readSink, characteristic)
    }

    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        sendNext(_writeSink, characteristic)
    }

    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        sendNext(_notifySink, characteristic)
    }

    func peripheral(peripheral: CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {

    }

    func peripheral(peripheral: CBPeripheral!, didUpdateValueForDescriptor descriptor: CBDescriptor!, error: NSError!) {

    }

    func peripheral(peripheral: CBPeripheral!, didWriteValueForDescriptor descriptor: CBDescriptor!, error: NSError!) {
        
    }
}
