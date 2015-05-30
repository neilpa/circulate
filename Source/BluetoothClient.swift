//
//  BluetoothClient.swift
//  Circulate
//
//  Created by Neil Pankey on 5/26/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

public final class BluetoothClient {
    private let central: CentralManager

    public init() {
        let central = CentralManager()
        self.central = central
    }

    // TODO Should be the service IDs for Input, and probable a timeout
    public private(set) lazy var scan: Action<(), CBPeripheral, NoError> = Action { input in
        return self.central.scan([])
    }

    public func connect(peripheral: CBPeripheral) -> SignalProducer<BluetoothDevice, NoError> {
        // TODO
        return self.central.connect(peripheral)
            |> map { _ in BluetoothDevice(peripheral: peripheral) }
            |> on(next: println)
    }
}
