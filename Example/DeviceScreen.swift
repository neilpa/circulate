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
import Rex

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

    @IBOutlet weak var connectingIndicator: UIActivityIndicatorView!

    @IBOutlet weak var targetTemp: UILabel!
    @IBOutlet weak var currentTemp: UILabel!

    @IBOutlet weak var timerStatus: UILabel!

    @IBOutlet weak var deviceStatus: UILabel!

    @IBOutlet weak var startStop: UIButton!

    lazy var connectAction: Action<Any?, AnovaDevice, NSError> = Action { _ in
        return AnovaDevice.connect(self.central, peripheral: self.peripheral)
            |> observeOn(UIScheduler())
    }

    var device: MutableProperty<AnovaDevice?> = MutableProperty(nil)

    override func viewDidLoad() {
        connectAction.executing.producer.start(next: {
            $0 ? self.connectingIndicator.startAnimating() : self.connectingIndicator.stopAnimating()
        })

        device <~ connectAction.values |> scan(nil) { $1 }

        bindLabel(targetTemp) { $0.targetTemperature }
        bindLabel(currentTemp) { $0.currentTemperature }
        bindLabel(deviceStatus) { $0.status }

        connectAction.apply(nil).start()
    }

    private func bindLabel<T>(label: UILabel, transform: AnovaDevice -> SignalProducer<T, NSError>) {
        DynamicProperty(object: label, keyPath: "text") <~ device.producer
            |> flatMap(.Latest) {
                if let device = $0 {
                    return transform(device)
                        |> ignoreError // TODO Handle failures
                        // DynamicProperty requires AnyObject
                        |> map {
                            return toString($0) as AnyObject
                        }
                } else {
                    return SignalProducer(value: "--")
                }
            }
            |> observeOn(UIScheduler())
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "temp" {
            if let picker = segue.destinationViewController as? TemperaturePicker {
                picker.device = self.device.value
            }
        }
    }
}
