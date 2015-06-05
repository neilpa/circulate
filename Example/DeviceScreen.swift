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

func loadViewController<T: UIViewController>(storyboardId: String, viewControllerId: String) -> T {
    let storyboard = UIStoryboard(name: storyboardId, bundle: nil)
    return storyboard.instantiateViewControllerWithIdentifier(viewControllerId) as! T
}

class DeviceScreen: UIViewController {
    var central: CentralManager!
    var peripheral: CBPeripheral!

    override func viewDidLoad() {
    }

    @IBAction func onConnect(sender: AnyObject) {
        AnovaDevice.connect(self.central, peripheral: peripheral)
            |> observeOn(UIScheduler())
            |> start(next: { device in
                let tempController: TempController = loadViewController("Main", "TempController")
                tempController.device = device

                tempController.view.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: self.view.frame.height - 100)
                self.addChildViewController(tempController)
                self.view.addSubview(tempController.view)
            })
    }
}
