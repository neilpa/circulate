//
//  Temperature.swift
//  Circulate
//
//  Created by Neil Pankey on 6/3/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

public enum TemperatureScale {
    case Farenheit, Celsius

    public init?(scale: String) {
        switch scale {
        case "f", "F":
            self = .Farenheit
        case "c", "C":
            self = .Celsius
        default:
            return nil
        }
    }
}

public struct Temperature {
    public let scale: TemperatureScale
    public let degrees: Float

    public static func farenheit(degrees: Float) -> Temperature {
        return self(scale: .Farenheit, degrees: degrees)
    }

    public static func celsius(degrees: Float) -> Temperature {
        return self(scale: .Celsius, degrees: degrees)
    }

    public init(scale: TemperatureScale, degrees: Float) {
        self.scale = scale
        self.degrees = degrees
    }

    public func analysis<T>(#ifFarenheit: Float -> T, ifCelsius: Float -> T) -> T {
        switch scale {
        case .Farenheit:
            return ifFarenheit(degrees)
        case .Celsius:
            return ifCelsius(degrees)
        }
    }
}

extension TemperatureScale: Printable {
    public var description: String {
        switch self {
        case .Farenheit: return "F"
        case .Celsius: return "C"
        }
    }
}

extension Temperature: Printable {
    public var description: String {
        return "\(degrees)˚ \(scale)"
    }
}
