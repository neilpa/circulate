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
    private let peripheral: Peripheral

    public let readCurrentTemp: Action<(), Temperature, NSError>
    public let readTargetTemp: Action<(), Temperature, NSError>
//    public let setTargetTemp: Action<Temperature, Temperature, NSError>

    public let readStatus: Action<(), AnovaStatus, NSError>
    public let startDevice: Action<(), AnovaStatus, NSError>
    public let stopDevice: Action<(), AnovaStatus, NSError>

    public let status: PropertyOf<AnovaStatus?>
    public let currentTemp: PropertyOf<Temperature?>
    public let targetTemp: PropertyOf<Temperature?>

    public var name: String {
        return peripheral.name
    }

    public var identifier: String {
        return peripheral.identifier
    }

    public init(peripheral: Peripheral, characteristic: CBCharacteristic) {
        self.peripheral = peripheral
        let queue = CommandQueue(peripheral: peripheral, characteristic: characteristic)

        readCurrentTemp = Action { queue.readCurrentTemperature() }
        currentTemp = PropertyOf(SignalProperty(nil, readCurrentTemp.values |> optionalize))

        readTargetTemp = Action { queue.readTargetTemperature() }
        targetTemp = PropertyOf(SignalProperty(nil, readTargetTemp.values |> optionalize))

        readStatus = Action { queue.readStatus() }
        startDevice = Action { queue.startDevice() |> then(queue.readStatus()) }
        stopDevice = Action { queue.stopDevice() |> then(queue.readStatus()) }

        let statusSignal = merge(readStatus.values, startDevice.values, stopDevice.values)
        status = PropertyOf(SignalProperty(nil, statusSignal |> optionalize))
    }

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
