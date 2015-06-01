//
//  CentralManagerDelegate.swift
//  Circulate
//
//  Created by Neil Pankey on 5/30/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa
import Result

// TODO Better types for these
public typealias ScanResult = (CBPeripheral, [NSObject: AnyObject], NSNumber)
public typealias ConnectResult = (CBPeripheral, NSError?)

// Delegate for `CBCentralManager` exposing signals for the `CBCentralManagerDelegate` methods.
internal final class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
    let scanSignal: Signal<ScanResult, NoError>
    private let _scanSink: Signal<ScanResult, NoError>.Observer

    let connectSignal: Signal<ConnectResult, NoError>
    private let _connectSink: Signal<ConnectResult, NoError>.Observer

    let status: PropertyOf<CBCentralManagerState>
    private let _status: MutableProperty<CBCentralManagerState>

    internal required init(central: CBCentralManager) {
        (scanSignal, _scanSink) = Signal<ScanResult, NoError>.pipe()
        (connectSignal, _connectSink) = Signal<ConnectResult, NoError>.pipe()

        _status = MutableProperty(central.state)
        status = PropertyOf(_status)

        super.init()
        central.delegate = self
    }

    func centralManagerDidUpdateState(central: CBCentralManager!) {
        _status.value = central.state
    }

    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        sendNext(_scanSink, (peripheral, advertisementData, RSSI))
    }

    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        sendNext(_connectSink, (peripheral, nil))
    }

    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        sendNext(_connectSink, (peripheral, error ?? NSError()))
    }
}
