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

        let (producer, sink) = SignalProducer<(String, Signal<String, NSError>.Observer), NSError>.buffer()
        queue = sink

        producer
            |> flatMap(.Concat) { (command: String, observer: Signal<String, NSError>.Observer) -> SignalProducer<String, NSError> in
            // TODO Push more of this into Peripheral (or somewhere)
            let data = "\(command)\r".dataUsingEncoding(NSASCIIStringEncoding)!
            return peripheral.execute(data, characteristic: characteristic)
                |> tryMap {
                    println("executing \(command)")
                    if let string = NSString(data: $0.value, encoding: NSASCIIStringEncoding) as? String {
                        // strip the trailing \r
                        // TODO some responses span multiple lines
                        let response = string.substringToIndex(string.endIndex.predecessor())
                        return .success(response)
                    }
                    // TODO Proper error
                    return .failure(NSError())
                }
                // Forward to the real observer
                |> on(event: { observer.put($0) })
            }
            |> start()
    }

    public static func connect(central: CentralManager, peripheral: CBPeripheral) -> SignalProducer<AnovaDevice, NSError> {
        return central.connect(peripheral)
            |> flatMap(.Latest) { (periph: Peripheral) in
                return periph.discoverServices([CBUUID(string: "FFE0")])
                    |> flatMap(.Latest) {
                        periph.discoverCharacteristics(nil, service: $0)
                    }
                    |> flatMap(.Latest) {
                        periph.setNotifyValue(true, characteristic: $0)
                    }
                    |> map {
                        return AnovaDevice(peripheral: periph, characteristic: $0)
                    }
            }
    }

    public func readCurrentTemperature() -> SignalProducer<Temperature, NSError> {
        return readTemperature("read temp")
            |> logEvents("current temperature")
    }

    public func readTargetTemperature() -> SignalProducer<Temperature, NSError> {
        return readTemperature("read set temp")
            |> logEvents("target temperature")
    }

    private func readTemperature(command: String) -> SignalProducer<Temperature, NSError> {
        return queueCommand("read unit")
            |> concat(queueCommand(command))
            |> collect
            |> tryMap { response in
                // TODO proper response parsing
                switch (response[0], (response[1] as NSString).floatValue) {
                case let ("c", degrees):
                    return .success(.Celcius(degrees))
                case let ("f", degrees):
                    return .success(.Farenheit(degrees))
                default:
                    // TODO Proper error
                    return .failure(NSError())
                }
            }
    }

    private func queueCommand(command: String) -> SignalProducer<String, NSError> {
        return SignalProducer { observer, _ in
            println("queueing \(command)")
            sendNext(self.queue, (command, observer))
            // TODO Deque commands
        }
    }
}
