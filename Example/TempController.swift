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
        bindTemperature(currentTemperature) { $0.currentTemperature }
        bindTemperature(targetTemperature) { $0.targetTemperature }
    }

    private func bindTemperature(label: UILabel, transform: AnovaDevice -> SignalProducer<Temperature, NSError>) {
        DynamicProperty(object: label, keyPath: "text") <~ deviceProperty.producer
            |> flatMap(.Latest) {
                if let device = $0 {
                    return transform(device)
                        |> ignoreError
                        // DynamicProperty requires AnyObject
                        |> map { toString($0) as AnyObject }
                } else {
                    return SignalProducer(value: "??")
                }
            }
            |> observeOn(UIScheduler())
    }
}
