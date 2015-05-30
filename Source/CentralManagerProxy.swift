//
//  CentralManagerProxy.swift
//  Circulate
//
//  Created by Neil Pankey on 5/30/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

// Proxy and delegate for `CBCentralManager` exposing signals for the `CBCentralManagerDelegate` methods.
internal final class CentralManagerProxy: NSObject, CBCentralManagerDelegate {
    private let central: CBCentralManager

    let scanSignal: Signal<CBPeripheral, NoError>
    private let _scanSink: Signal<CBPeripheral, NoError>.Observer

    let connectionSignal: Signal<(CBPeripheral, ConnectionStatus), NoError>
    private let _connectionSink: Signal<(CBPeripheral, ConnectionStatus), NoError>.Observer

    let status: PropertyOf<CBCentralManagerState>
    private let _status: MutableProperty<CBCentralManagerState>

    required init(_ central: CBCentralManager) {
        (scanSignal, _scanSink) = Signal<CBPeripheral, NoError>.pipe()
        (connectionSignal, _connectionSink) = Signal<(CBPeripheral, ConnectionStatus), NoError>.pipe()

        _status = MutableProperty(central.state)
        status = PropertyOf(_status)

        self.central = central
        super.init()
        central.delegate = self
    }

    func scan(services: [CBUUID]!) {
        central.scanForPeripheralsWithServices(services, options: nil)
    }

    func stopScan() {
        central.stopScan()
    }

    func connect(peripheral: CBPeripheral) {
        central.connectPeripheral(peripheral, options: nil)
    }

    func disconnect(peripheral: CBPeripheral) {
        central.cancelPeripheralConnection(peripheral)
    }

    func centralManagerDidUpdateState(central: CBCentralManager!) {
        _status.value = central.state
    }

    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        sendNext(_scanSink, peripheral)
    }

    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        sendNext(_connectionSink, (peripheral, .Connected))
    }

    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        sendNext(_connectionSink, (peripheral, .Error(error)))
    }

    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        sendNext(_connectionSink, (peripheral, .Disconnected(error)))
    }
}
