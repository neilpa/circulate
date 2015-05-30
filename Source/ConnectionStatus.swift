//
//  ConnectionStatus.swift
//  Circulate
//
//  Created by Neil Pankey on 5/28/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth

public enum ConnectionStatus: Equatable {
    case Connected
    case Disconnected(NSError?) // Permanent
    case Error(NSError) // Potentially transient
}

public func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
    switch (lhs, rhs) {
    case (.Connected, .Connected):
        return true
    case let (.Disconnected(left), .Disconnected(right)):
        return left == right
    case let (.Error(left), .Error(right)):
        return left == right
    default:
        return false
    }
}
