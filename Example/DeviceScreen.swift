//
//  DeviceScreen.swift
//  Circulate
//
//  Created by Neil Pankey on 5/28/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import Circulate
import ReactiveCocoa

class DeviceScreen: UIViewController {
    @IBOutlet weak var tempLabel: UILabel!

    var device: AnovaDevice?

    override func viewDidLoad() {
        if let device = self.device {
            device.execute("")
                |> start()
        }

    }
}
