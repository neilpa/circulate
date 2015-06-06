//
//  Temperature.swift
//  Circulate
//
//  Created by Neil Pankey on 6/3/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

public enum Temperature {
    case Farenheit(Float)
    case Celcius(Float)

    public func analysis<T>(#ifFarenheit: Float -> T, ifCelcius: Float -> T) -> T {
        switch self {
        case let .Farenheit(degrees):
            return ifFarenheit(degrees)
        case let .Celcius(degrees):
            return ifCelcius(degrees)
        }
    }

    /// The raw degrees value ignoring temperature scale.
    public var degrees: Float {
        return analysis(ifFarenheit: { $0 }, ifCelcius: { $0 })
    }
}

extension Temperature: Printable {
    public var description: String {
        return analysis(ifFarenheit: { "\($0) F" }, ifCelcius: { "\($0) C" })
    }
}