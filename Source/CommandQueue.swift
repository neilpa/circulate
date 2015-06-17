//
//  CommandQueue.swift
//  Circulate
//
//  Created by Neil Pankey on 6/16/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa
import Result

// TODO Make this a real queue
public final class CommandQueue {
    private let peripheral: Peripheral
    private let characteristic: CBCharacteristic

    private let queue: Signal<(String, Signal<String, NSError>.Observer), NSError>.Observer

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

    public func readCurrentTemperature() -> SignalProducer<Temperature, NSError> {
        return readTemperature("read temp")
    }

    public func readTargetTemperature() -> SignalProducer<Temperature, NSError> {
        return readTemperature("read set temp")
    }

    public func startDevice() -> SignalProducer<String, NSError> {
        return queueCommand("start")
    }

    public func stopDevice() -> SignalProducer<String, NSError> {
        return queueCommand("stop")
    }

    public func readStatus() -> SignalProducer<AnovaStatus, NSError> {
        return queueCommand("status") |> tryMap {
            if let status = AnovaStatus(rawValue: $0) {
                return .success(status)
            }
            return .failure(NSError())
        }
    }

    public func readTemperatureScale() -> SignalProducer<TemperatureScale, NSError> {
        return queueCommand("read unit") |> tryMap {
            if let status = TemperatureScale(scale: $0) {
                return .success(status)
            }
            return .failure(NSError())
        }
    }

    public func readTargetDegrees() -> SignalProducer<Float, NSError> {
        return readDegrees("read set temp")
    }

    public func readCurrentDegrees() -> SignalProducer<Float, NSError> {
        return readDegrees("read temp")
    }

    private func readTemperature(command: String) -> SignalProducer<Temperature, NSError> {
        return zip(readTemperatureScale(), readDegrees(command))
            |> map { return Temperature(scale: $0, degrees: $1) }
    }

    private func readDegrees(command: String) -> SignalProducer<Float, NSError> {
        // TODO Better number parsing
        return queueCommand(command) |> map { ($0 as NSString).floatValue }
    }

    private func queueCommand(command: String) -> SignalProducer<String, NSError> {
        return SignalProducer { observer, _ in
            sendNext(self.queue, (command, observer))
            // TODO deque commands on disposal
        }
        |> logEvents("COMMAND: \(command)")
    }
}
