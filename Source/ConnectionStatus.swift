//
//  ConnectionStatus.swift
//  Circulate
//
//  Created by Neil Pankey on 5/28/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth

public enum ConnectionStatus {
    case Connecting
    case Connected
    case Disconnected(NSError?) // Permanent
    case Error(NSError) // Potentially transient

    public init(state: CBPeripheralState) {
        switch state {
        case .Disconnected:
            self = .Disconnected(nil)
        case .Connecting:
            self = .Connecting
        case .Connected:
            self = .Connected
        }
    }
}

