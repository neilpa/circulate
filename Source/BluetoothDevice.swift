//
//  BluetoothDevice.swift
//  Circulate
//
//  Created by Neil Pankey on 5/27/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

public final class BluetoothDevice: NSObject, CBPeripheralDelegate {
    private let peripheral: CBPeripheral
    private let central: CBCentralManager

    public var name: String {
        return peripheral.name ?? ""
    }

    public var identifier: String {
        return peripheral.identifier.UUIDString
    }

    public var services: [AnyObject] {
        return peripheral.services
    }

    internal init(peripheral: CBPeripheral, central: CBCentralManager) {
        self.peripheral = peripheral
        self.central = central

        super.init()
        peripheral.delegate = self
    }

    public func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        println("services: \(peripheral.services)")
    }

    public func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        println("characteristics")
    }

    public func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("update char")
    }

    public func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("update value")
    }
}
