//
//  CBCentralManagerState.swift
//  Circulate
//
//  Created by Neil Pankey on 5/27/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth

extension CBCentralManagerState: Printable {
    public var description: String {
        switch self {
        case Unknown:
            return "Unknown"
        case Resetting:
            return "Resetting"
        case Unsupported:
            return "Unsupported"
        case Unauthorized:
            return "Unauthorized"
        case PoweredOff:
            return "PoweredOff"
        case PoweredOn:
            return "PoweredOn"
        }
    }
}