//
//  AnovaDevice.swift
//  Circulate
//
//  Created by Neil Pankey on 5/28/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa
import Rex

public final class AnovaDevice {
    private let peripheral: Peripheral
    private let characteristic: CBCharacteristic

    private let queue: Signal<(String, Signal<String, NSError>.Observer), NSError>.Observer

    public var name: String {
        return peripheral.name
    }

    public var identifier: String {
        return peripheral.identifier
    }

    public init(peripheral: Peripheral, characteristic: CBCharacteristic) {
        self.peripheral = peripheral
        self.characteristic = characteristic

        // Commands are pushed to this producer to serialize writes to the underlying peripheral
        let (sink, disposable) = serialize { (command: String) -> SignalProducer<String, NSError> in
            return peripheral.execute("\(command)\r", characteristic: characteristic)
                // strip the trailing \r
                // TODO some responses span multiple lines
                |> map {
                    let res = $0.substringToIndex($0.endIndex.predecessor())
                    return res
            }
        }
        queue = sink
    }

    public static func connect(central: CentralManager, peripheral: CBPeripheral) -> SignalProducer<AnovaDevice, NSError> {
        return central.connect(peripheral)
            |> flatMap(.Merge) { (periph: Peripheral) in
                return periph.discoverServices([CBUUID(string: "FFE0")])
                    |> flatMap(.Merge) {
                        periph.discoverCharacteristics(nil, service: $0)
                    }
                    |> flatMap(.Merge) {
                        periph.setNotifyValue(true, characteristic: $0)
                    }
                    |> map {
                        return AnovaDevice(peripheral: periph, characteristic: $0)
                    }
            }
    }

    public private(set) lazy var temperatureScale: SignalProducer<TemperatureScale, NSError> = {
        return self.queueCommand("read unit") |> tryMap {
            if let scale = TemperatureScale(scale: $0) {
                return .success(scale)
            }
            return .failure(NSError())
        }
    }()

    public private(set) lazy var currentTemperature: SignalProducer<Temperature, NSError> = {
        return self.readTemperature("read temp")
    }()

    public private(set) lazy var targetTemperature: SignalProducer<Temperature, NSError> = {
        return self.readTemperature("read set temp")
    }()

    private func readTemperature(command: String) -> SignalProducer<Temperature, NSError> {
        return zip(temperatureScale, rawTemperature(command))
            |> map { return Temperature(scale: $0, degrees: $1) }
    }

    private func rawTemperature(command: String) -> SignalProducer<Float, NSError> {
        // TODO Better number parsing
        return queueCommand(command) |> map { ($0 as NSString).floatValue }
    }

    private func queueCommand(command: String) -> SignalProducer<String, NSError> {
        return SignalProducer { observer, _ in
            sendNext(self.queue, (command, observer))

            // TODO deque commands on disposal
        }
    }
}
