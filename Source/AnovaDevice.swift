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
    private let peripheral: Peripheral

    public var name: String {
        return peripheral.name
    }

    public var identifier: String {
        return peripheral.identifier
    }
    
    public init(peripheral: Peripheral) {
        self.peripheral = peripheral
    }

    public func execute(command: String) -> SignalProducer<(), NoError> {
        // TODO Using this inline breaks type-inference somewhere
        let writer: CBCharacteristic -> SignalProducer<CBCharacteristic, NoError> = {
            let string = "\(command)\r" as NSString
            let data = string.dataUsingEncoding(NSASCIIStringEncoding)!
            return self.peripheral.write(data, characteristic: $0, type: .WithResponse)
        }

        return peripheral.discoverServices(nil)
            |> flatMap(.Merge) {
                return self.peripheral.discoverCharacteristics($0)
            }
            |> flatMap(.Merge) {
                return self.peripheral.notify($0)
            }
            |> flatMap(.Merge) {
                writer($0)
            }
            |> map {
                println(NSString(data: $0.value, encoding: NSASCIIStringEncoding))
                return ()
            }
    }
}
