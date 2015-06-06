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

extension CocoaAction {
    public convenience init<Output, Error>(_ action: Action<(), Output, Error>) {
        self.init(action, { _ in })
    }
}

class DeviceScreen: UIViewController {
    var central: CentralManager!
    var peripheral: CBPeripheral!

    @IBOutlet weak var connectButton: UIButton!
    var connectAction: CocoaAction!

    override func viewDidLoad() {
        let connect: Action<(), AnovaDevice, NSError> = Action { _ in
            return AnovaDevice.connect(self.central, peripheral: self.peripheral)
                |> observeOn(UIScheduler())
        }

        connectAction = CocoaAction(connect)
        connectButton.addTarget(connectAction, action: CocoaAction.selector, forControlEvents: .TouchUpInside)

        connect.values.observe(next: { device in
            let tempController: TempController = loadViewController("Main", "TempController")
            tempController.deviceProperty.value = device

            tempController.view.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: self.view.frame.height - 100)
            self.addChildViewController(tempController)
            self.view.addSubview(tempController.view)
        })
    }
}
