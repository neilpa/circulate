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
    private let queue: CommandQueue

    public var name: String {
        return peripheral.name
    }

    public var identifier: String {
        return peripheral.identifier
    }

    public init(peripheral: Peripheral, characteristic: CBCharacteristic) {
        self.peripheral = peripheral
        queue = CommandQueue(peripheral: peripheral, characteristic: characteristic)
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

    public private(set) lazy var startDevice: Action<(), String, NSError> = {
        return Action { self.queue.startDevice() }
    }()

    public private(set) lazy var stopDevice: Action<(), String, NSError> = {
        return Action { self.queue.stopDevice() }
    }()

    public private(set) lazy var currentTemperature: PropertyOf<Temperature?> = {
        makeProperty(self.queue.readCurrentTemperature())
    }()

    public private(set) lazy var targetTemperature: PropertyOf<Temperature?> = {
        makeProperty(self.queue.readTargetTemperature())
    }()

    public private(set) lazy var status: PropertyOf<AnovaStatus?> = {
        makeProperty(self.queue.readStatus())
    }()
}

private func makeProperty<T>(producer: SignalProducer<T, NSError>) -> PropertyOf<T?> {
    return PropertyOf(SignalProperty(nil, producer |> optionalize |> ignoreError))
}
