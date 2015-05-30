//
//  AnovaDevice.swift
//  Circulate
//
//  Created by Neil Pankey on 5/28/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import ReactiveCocoa

public enum AnovaCommand {
    // TODO
}

public final class AnovaDevice {
    private let device: BluetoothDevice

    public init(device: BluetoothDevice) {
        self.device = device
    }

    public func execute(command: String) -> SignalProducer<(), NoError> {
        return .never
    }
}
