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

class DeviceScreen: UIViewController {
    var central: CentralManager!
    let peripheral: MutableProperty<CBPeripheral?> = MutableProperty(nil)
    let device: MutableProperty<AnovaDevice?> = MutableProperty(nil)

    @IBOutlet weak var connectingIndicator: UIActivityIndicatorView!

    @IBOutlet weak var targetTemp: UILabel!
    @IBOutlet weak var currentTemp: UILabel!

    @IBOutlet weak var timerStatus: UILabel!

    @IBOutlet weak var deviceStatus: UILabel!

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    override func viewDidLoad() {
        device <~ peripheral.producer
            |> promoteErrors(NSError)
            |> flatMap(.Latest) {
                if let device = $0 {
                    return AnovaDevice.connect(self.central, peripheral: device) |> optionalize
                }
                return SignalProducer(error: NSError())
            }
            |> catch { _ in SignalProducer(value: nil) }

        DynamicProperty(object: targetTemp, keyPath: "text") <~ device.producer
            |> ignoreNil // TODO Handle nil
            |> flatMap(FlattenStrategy.Latest) {
                $0.readTargetTemp.apply(())
                    |> ignoreError
                    |> map { toString($0) as AnyObject }
            }
            |> observeOn(UIScheduler())

        DynamicProperty(object: currentTemp, keyPath: "text") <~ device.producer
            |> ignoreNil // TODO Handle nil
            |> flatMap(FlattenStrategy.Latest) {
                $0.readCurrentTemp.apply(())
                    |> ignoreError
                    |> map { toString($0) as AnyObject }
            }
            |> observeOn(UIScheduler())

        DynamicProperty(object: deviceStatus, keyPath: "text") <~ device.producer
            |> ignoreNil // TODO Handle nil
            |> flatMap(FlattenStrategy.Latest) {
                $0.readStatus.apply(())
                    |> ignoreError
                    |> map { toString($0) as AnyObject }
            }
            |> observeOn(UIScheduler())
    }

    func start() {
        device.value?.startDevice.apply(()).start()
    }

    func stop() {
        device.value?.stopDevice.apply(()).start()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "temp" {
            if let picker = segue.destinationViewController as? TemperaturePicker {
                picker.device = self.device.value
            }
        }
    }
}
