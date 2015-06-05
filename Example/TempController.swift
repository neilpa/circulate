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
            |> start(next: {
                self.tempLabel.text = toString($0.degrees)
            })
    }
}
