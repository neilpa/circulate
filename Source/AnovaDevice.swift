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

public enum AnovaStatus: String {
    case Running = "running"
    case Stopped = "stopped"
    case LowWater = "low water"
    case HeaterError = "heater error"
    case PowerInterrupt = "power interrupt error"
}

extension AnovaStatus: Printable {
    public var description: String {
        return rawValue
    }
}

public enum TimerStatus: String {
    case Running = "running"
    case Stopped = "stopped"
}

public final class AnovaDevice {
    public let readCurrentTemp: Action<(), Temperature, NSError>
    public let readTargetTemp: Action<(), Temperature, NSError>
//    public let setTargetTemp: Action<Temperature, Temperature, NSError>

    public let readStatus: Action<(), AnovaStatus, NSError>
    public let startDevice: Action<(), AnovaStatus, NSError>
    public let stopDevice: Action<(), AnovaStatus, NSError>

    public let status: PropertyOf<AnovaStatus?>
    public let running: PropertyOf<Bool>

    public let currentTemp: PropertyOf<Temperature?>
    public let targetTemp: PropertyOf<Temperature?>

    public init(peripheral: Peripheral, characteristic: CBCharacteristic) {
        let queue = CommandQueue(peripheral: peripheral, characteristic: characteristic)

        readCurrentTemp = Action { queue.readCurrentTemperature() }
        currentTemp = readCurrentTemp.values |> optionalize |> propertyOf(nil)

        readTargetTemp = Action { queue.readTargetTemperature() }
        targetTemp = readTargetTemp.values |> optionalize |> propertyOf(nil)

        readStatus = Action { queue.readStatus() }
        startDevice = Action { queue.startDevice() |> then(queue.readStatus()) }
        stopDevice = Action { queue.stopDevice() |> then(queue.readStatus()) }

        let statusSignal = merge(readStatus.values, startDevice.values, stopDevice.values)
        status = statusSignal |> optionalize |> propertyOf(nil)
        running = statusSignal |> map { $0 == .Running } |> propertyOf(false)
    }

    // TODO Turn this into a per-instance action
    public static func connect(central: CentralManager, peripheral: CBPeripheral) -> SignalProducer<AnovaDevice, NSError> {
        return central.connect(peripheral)
            |> flatMap(.Merge) { (periph: Peripheral) in
                return periph.discoverServices([CBUUID(string: "FFE0")])
                    |> flatMap(.Merge) {
                        periph.discoverCharacteristics([CBUUID(string: "FFE1")], service: $0)
                    }
                    |> flatMap(.Merge) {
                        periph.setNotifyValue(true, characteristic: $0)
                    }
                    |> map {
                        return AnovaDevice(peripheral: periph, characteristic: $0)
                    }
            }
    }
}
