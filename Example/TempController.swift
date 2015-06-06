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
    @IBOutlet weak var targetTemperature: UILabel!
    @IBOutlet weak var currentTemperature: UILabel!

    var device: AnovaDevice!

    override func viewDidLoad() {
        zip(device.readCurrentTemperature(), device.readTargetTemperature())
            |> observeOn(UIScheduler())
            |> start(next: { current, target in
                self.currentTemperature.text = current.description
                self.targetTemperature.text = target.description
            })
    }
}
