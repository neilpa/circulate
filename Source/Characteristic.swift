//
//  Characteristic.swift
//  Circulate
//
//  Created by Neil Pankey on 6/1/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

/// Wrapper around `CBCharacteristic` exposing a RAC interface.
public final class Characteristic {
    private let characteristic: CBCharacteristic

    public let value: PropertyOf<NSData?>
    private let _value: MutableProperty<NSData?>

    internal init(characteristic: CBCharacteristic) {
        self.characteristic = characteristic

        _value = MutableProperty(characteristic.value)
        value = PropertyOf(_value)
    }

    deinit {
        characteristic.service.peripheral.setNotifyValue(false, forCharacteristic: characteristic)
    }

}