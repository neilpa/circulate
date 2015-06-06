//
//  TempController.swift
//  Circulate
//
//  Created by Neil Pankey on 6/5/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import Circulate
import CoreBluetooth
import ReactiveCocoa
import Rex

class TempController: UIViewController {
    @IBOutlet weak var targetTemperature: UILabel!
    @IBOutlet weak var currentTemperature: UILabel!

    var deviceProperty: MutableProperty<AnovaDevice?> = MutableProperty(nil)

    override func viewDidLoad() {
        let current: SignalProducer<String, NoError> = deviceProperty.producer
            |> flatMap(.Latest) {
                if let device = $0 {
                    return device.readCurrentTemperature()
                        |> ignoreError
                        |> map(toString)
                } else {
                    println("Empty current")
                    return SignalProducer(value: "??")
                }
            }
            |> observeOn(UIScheduler())

        let target: SignalProducer<String, NoError> = deviceProperty.producer
            |> flatMap(.Latest) {
                if let device = $0 {
                    return device.readTargetTemperature()
                        |> ignoreError
                        |> map(toString)
                } else {
                    println("Empty target")
                    return SignalProducer(value: "??")
                }
            }
            |> observeOn(UIScheduler())

        DynamicProperty(object: targetTemperature, keyPath: "text") <~ current |> map { $0 }
        DynamicProperty(object: currentTemperature, keyPath: "text") <~ target |> map { $0 }
    }
}
