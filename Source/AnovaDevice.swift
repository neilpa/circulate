//
//  AnovaDevice.swift
//  Circulate
//
//  Created by Neil Pankey on 5/28/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

public enum AnovaCommand {
    // TODO
}

public final class AnovaDevice {
    private let peripheral: CBPeripheral

    public var name: String {
        return peripheral.name ?? ""
    }

    public var identifier: String {
        return peripheral.identifier.UUIDString
    }
    
    public init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }

    public func execute(command: String) -> SignalProducer<(), NoError> {
        return .never
    }
}
