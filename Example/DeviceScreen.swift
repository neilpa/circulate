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

        (device.producer
            |> ignoreNil
            |> map { device in
                // Fetch the new state whenever the device changes
                return device.readCurrentTemp.apply(())
                    |> then(device.readTargetTemp.apply(()))
                    |> then(device.readStatus.apply(()))
                    |> ignoreError
            }
            |> flatten(.Latest))
            // For some reason the compiler barfs when using |> start()
            .start()

        currentTemp.rex_text <~ device.producer
            |> flatMapUI(.Latest, placeholder: "--") {
                $0.currentTemp.producer |> map {
                    $0.map(toString) ?? "--"
                }
            }

        targetTemp.rex_text <~ device.producer
            |> flatMapUI(.Latest, placeholder: "--") {
                $0.targetTemp.producer |> map {
                    $0.map(toString) ?? "--"
                }
            }

        deviceStatus.rex_text <~ device.producer
            |> flatMapUI(.Latest, placeholder: "--") {
                $0.status.producer |> map {
                    $0.map(toString) ?? "--"
                }
            }

        startButton.rac_pressed <~ device.producer
            |> ignoreNil // TODO Handle nil
            |> map { CocoaAction($0.startDevice, input: ()) }
            |> observeOn(UIScheduler())

        stopButton.rac_pressed <~ device.producer
            |> ignoreNil // TODO Handle nil
            |> map { CocoaAction($0.stopDevice, input: ()) }
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
