//
//  PeripheralProxy.swift
//  Circulate
//
//  Created by Neil Pankey on 5/30/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

// Proxy and delegate for `CBPeripheral` exposing signals for the `CBPeripheralDelegate` methods.
internal final class PeripheralProxy: NSObject, CBPeripheralDelegate {
    private let peripheral: CBPeripheral

    // TODO Make this a property?
    let nameSignal: Signal<String, NoError>
    private let _nameSink: Signal<String, NoError>.Observer

    let serviceSignal: Signal<[CBService], NSError>
    private let _serivceSink: Signal<[CBService], NSError>.Observer

    let characteristicSignal: Signal<CBService, NoError>
    private let _characteristicSink: Signal<CBService, NoError>.Observer

    let readSignal: Signal<CBCharacteristic, NoError>
    private let _readSink: Signal<CBCharacteristic, NoError>.Observer

    let writeSignal: Signal<CBCharacteristic, NoError>
    private let _writeSink: Signal<CBCharacteristic, NoError>.Observer

    let updateSignal: Signal<CBCharacteristic, NoError>
    private let _updateSink: Signal<CBCharacteristic, NoError>.Observer

    init(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral

        (nameSignal, _nameSink) = Signal<String, NoError>.pipe()
        (serviceSignal, _serivceSink) = Signal<[CBService], NSError>.pipe()
        (characteristicSignal, _characteristicSink) = Signal<CBService, NoError>.pipe()

        (readSignal, _readSink) = Signal<CBCharacteristic, NoError>.pipe()
        (writeSignal, _writeSink) = Signal<CBCharacteristic, NoError>.pipe()
        (updateSignal, _updateSink) = Signal<CBCharacteristic, NoError>.pipe()

        super.init()
        peripheral.delegate = self
    }

    var identifier: String {
        return peripheral.identifier.UUIDString
    }

    var name: String {
        // Names are incorrectly declared as implicitly-unwrapped optionals
        return peripheral.name ?? ""
    }

    func discoverServices(services: [CBUUID]?) {
        peripheral.discoverServices(services)
    }

    func discoverCharacteristics(service: CBService) {
        peripheral.discoverCharacteristics(nil, forService: service)
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
        sendNext(_updateSink, characteristic)
    }

    func peripheral(peripheral: CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {

    }

    func peripheral(peripheral: CBPeripheral!, didUpdateValueForDescriptor descriptor: CBDescriptor!, error: NSError!) {

    }

    func peripheral(peripheral: CBPeripheral!, didWriteValueForDescriptor descriptor: CBDescriptor!, error: NSError!) {
        
    }
}
