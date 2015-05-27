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

    public lazy var connect: Action<(), (), NoError> = Action { _ in
        return .never
    }

    public lazy var disconnect: Action<(), (), NoError> = Action { _ in
        return .never
    }

    internal init(peripheral: CBPeripheral, central: CBCentralManager) {
        self.peripheral = peripheral
        self.central = central
    }
}
