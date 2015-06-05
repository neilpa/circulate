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

public enum AnovaCommand {
    // TODO
}

public final class AnovaDevice {
    private let peripheral: Peripheral
    private let characteristic: CBCharacteristic

    private lazy var commands: Action<String, String, NSError> = Action { self.executeCommand($0) }

//    private let queue: SignalProducer<(SignalProducer<String, NSError>, Signal<String, NSError>.Observer), NSError>
//    private let sink: Signal<(SignalProducer<String, NSError>, Signal<String, NSError>.Observer), NSError>.Observer

    public var name: String {
        return peripheral.name
    }

    public var identifier: String {
        return peripheral.identifier
    }

    public init(peripheral: Peripheral, characteristic: CBCharacteristic) {
        self.peripheral = peripheral
        self.characteristic = characteristic

        commands = Action { command in
            return self.executeCommand(command)
        }

//        (queue, sink) = SignalProducer<(SignalProducer<String, NSError>, Signal<String, NSError>.Observer), NSError>.buffer(0)
//        queue |> flatMap(.Concat) { producer, observer in
//            return producer
//        }
//        |> start()
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
            |> concat(executeCommand(command))
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
        return commands.apply(command)
            |> catch {
                switch $0 {
                case .NotEnabled:
                    println("Queuing")
                    return self.commands.enabled.producer
                        |> filter { $0 }
                        |> take(1)
                        |> promoteErrors(NSError.self)
                        |> then(self.queueCommand(command))
                case let .ProducerError(error):
                    return SignalProducer(error: error)
                }
            }
    }

    private func executeCommand(command: String) -> SignalProducer<String, NSError> {
        let data = "\(command)\r".dataUsingEncoding(NSASCIIStringEncoding)!
        return peripheral.execute(data, characteristic: characteristic)
            |> tryMap {
                if let string = NSString(data: $0.value, encoding: NSASCIIStringEncoding) as? String {
                    // strip the trailing \r
                    // TODO some responses span multiple lines
                    let response = string.substringToIndex(string.endIndex.predecessor())
                    return .success(response)
                }
                // TODO Proper error
                return .failure(NSError())
            }
    }
}
