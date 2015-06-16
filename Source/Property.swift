//
//  Property.swift
//  Circulate
//
//  Created by Neil Pankey on 6/15/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import ReactiveCocoa
import Rex

/// Essentially a deferred property that is updated via an action. The action's
/// `event` signal is monitored for to update `value` on next events and reset to
/// `nil` on error events.
public struct ActionProperty<Input, Output, Error: ErrorType>: PropertyType {
    private let property: MutableProperty<Output?> = MutableProperty(nil)

    public var value: Output? {
        return property.value
    }

    public var producer: SignalProducer<Output?, NoError> {
        return property.producer
    }

    public let action: Action<Input, Output, Error>

    public init(action: Action<Input, Output, Error>) {
        self.action = action

        property <~ action.events |> filterMap {
            switch $0 {
            case let .Next(value):
                return .Some(.Some(value.value))
            case let .Error(error):
                return .Some(nil)
            case .Interrupted, .Completed:
                return nil
            }
        }
    }
}

