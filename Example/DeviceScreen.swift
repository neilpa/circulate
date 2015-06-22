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
    let deviceProperty: MutableProperty<AnovaDevice?> = MutableProperty(nil)

    @IBOutlet weak var targetTemp: UILabel!
    @IBOutlet weak var currentTemp: UILabel!

    @IBOutlet weak var timerStatus: UILabel!

    @IBOutlet weak var deviceStatus: UILabel!

    @IBOutlet weak var startStop: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    override func viewDidLoad() {
        deviceProperty <~ peripheral.producer
            |> promoteErrors(NSError)
            |> flatMap(.Latest) {
                if let device = $0 {
                    return AnovaDevice.connect(self.central, peripheral: device) |> optionalize
                }
                return SignalProducer(error: NSError())
            }
            |> catch { _ in SignalProducer(value: nil) }

        // TODO What to do with nil?
        let device = deviceProperty.producer |> ignoreNil
        let status = device |> flatMap(.Latest) { $0.status.producer }

        (deviceProperty.producer
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

        currentTemp.rex_text <~ deviceProperty.producer
            |> flatMapUI(.Latest, placeholder: "--") {
                $0.currentTemp.producer |> map {
                    $0.map(toString) ?? "--"
                }
            }

        targetTemp.rex_text <~ deviceProperty.producer
            |> flatMapUI(.Latest, placeholder: "--") {
                $0.targetTemp.producer |> map {
                    $0.map(toString) ?? "--"
                }
            }

        deviceStatus.rex_text <~ deviceProperty.producer
            |> flatMapUI(.Latest, placeholder: "--") {
                $0.status.producer |> map {
                    $0.map(toString) ?? "--"
                }
            }

        startStop.rac_pressed <~ combineLatest(device, status)
            |> map { device, status in
                switch status {
                case .Some(.Running):
                    return CocoaAction(device.stopDevice, input: ())
                default:
                    return CocoaAction(device.startDevice, input: ())
                }
            }

        startStop.rac_pressed.producer
            |> flatMap(.Latest) { $0.rex_executingProducer }
            |> combineLatestWith(status)
            |> map {
                switch ($0, $1) {
                case (true, _):
                    return "---"
                case (_, .Some(.Running)):
                    return "STOP"
                default:
                    return "START"
                }
            }
            |> observeOn(UIScheduler())
            |> start(next: { title in
                self.startStop.setTitle(title, forState: .Normal)
            })
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "temp" {
            if let picker = segue.destinationViewController as? TemperaturePicker {
                picker.device = self.deviceProperty.value
            }
        }
    }
}
