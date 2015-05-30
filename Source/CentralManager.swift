//
//  CentralManager.swift
//  Circulate
//
//  Created by Neil Pankey on 5/29/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

// Wraps a `CBCentralManager` exposing signals for the `CBCentralManagerDelegate` methods.
public final class CentralManager: NSObject, CBCentralManagerDelegate {
    private let central: CBCentralManager

    public let scanSignal: Signal<CBPeripheral, NoError>
    private let _scanSink: Signal<CBPeripheral, NoError>.Observer

    public let connectionSignal: Signal<(CBPeripheral, ConnectionStatus), NoError>
    private let _connectionSink: Signal<(CBPeripheral, ConnectionStatus), NoError>.Observer

    public let status: PropertyOf<CBCentralManagerState>
    private let _status: MutableProperty<CBCentralManagerState>

    public required init(central: CBCentralManager) {
        (scanSignal, _scanSink) = Signal<CBPeripheral, NoError>.pipe()
        (connectionSignal, _connectionSink) = Signal<(CBPeripheral, ConnectionStatus), NoError>.pipe()

        _status = MutableProperty(central.state)
        status = PropertyOf(_status)

        self.central = central
        super.init()
        central.delegate = self
    }

    public convenience override init() {
        let queue = dispatch_queue_create("me.neilpa.circulate.CentralManager", DISPATCH_QUEUE_SERIAL)
        self.init(central: CBCentralManager(delegate: nil, queue: queue))
    }

    // TODO Return a signal producer?
    public func scan() {
        central.scanForPeripheralsWithServices(nil, options: nil)
    }

    public func stopScan() {
        central.stopScan()
    }

    public func connect(peripheral: CBPeripheral) {
        central.connectPeripheral(peripheral, options: nil)
    }

    // MARK: CBCentralManagerDelegate
    // Sadly all of these have to be public

    public func centralManagerDidUpdateState(central: CBCentralManager!) {
        _status.value = central.state
    }

    public func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        sendNext(_scanSink, peripheral)
    }

    public func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        sendNext(_connectionSink, (peripheral, .Connected))
    }

    public func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        sendNext(_connectionSink, (peripheral, .Error(error)))
    }

    public func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        sendNext(_connectionSink, (peripheral, .Disconnected(error)))
    }
}
