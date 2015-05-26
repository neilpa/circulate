//
//  BluetoothClient.swift
//  Circulate
//
//  Created by Neil Pankey on 5/26/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

public final class BluetoothClient: NSObject, CBCentralManagerDelegate {
    private var central: CBCentralManager?

    public var stateProperty: MutableProperty<CBCentralManagerState> = MutableProperty(.Unknown)

    public lazy var scan: Action<(), CBPeripheral, NoError> = Action {
        return .never
    }

    public lazy var connect: Action<CBPeripheral, (), NoError> = Action { _ in
        return .never
    }

    public init(queue: dispatch_queue_t = dispatch_queue_create("me.neilpa.circulate.client", DISPATCH_QUEUE_SERIAL)) {
        super.init()
        central = CBCentralManager(delegate: self, queue: queue)
    }

    public func centralManagerDidUpdateState(central: CBCentralManager!) {
        stateProperty.value = central.state
    }

    public func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {

    }

    public func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {

    }

    public func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {

    }

    public func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        
    }
}
