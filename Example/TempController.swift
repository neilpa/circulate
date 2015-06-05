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

class TempController: UIViewController {
    @IBOutlet weak var tempLabel: UILabel!

    var device: AnovaDevice!

    override func viewDidLoad() {
        device.readCurrentTemperature()
            |> concat(device.readTargetTemperature())
            |> observeOn(UIScheduler())
            |> start(next: {
                println("Some temp reading \($0.degrees)")
                self.tempLabel.text = toString($0.degrees)
            })
    }
}
