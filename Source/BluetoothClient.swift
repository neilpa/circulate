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
        println("") // WTF why does this magically fix scanning?
        return self.central.scan([])
    }

    public func connect(peripheral: CBPeripheral) -> SignalProducer<BluetoothDevice, NoError> {
        return SignalProducer { observer, disposable in
            let signal = self.central.connectionSignal
                |> filter { $0.0 == peripheral  }
                |> map { BluetoothDevice(peripheral: $0.0) }

            disposable += signal.observe(observer)
            self.central.connect(peripheral)
        }
        |> on(next: println)
    }
}
