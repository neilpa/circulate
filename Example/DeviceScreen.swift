//
//  DeviceScreen.swift
//  Circulate
//
//  Created by Neil Pankey on 5/28/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import Circulate
import CoreBluetooth
import ReactiveCocoa

class DeviceScreen: UIViewController {
    @IBOutlet weak var tempLabel: UILabel!

    var central: CentralManager?
    var peripheral: CBPeripheral?

    override func viewDidLoad() {
        if let central = self.central, peripheral = self.peripheral {
            AnovaDevice.connect(central, peripheral: peripheral) |> start()
        }
    }
}
