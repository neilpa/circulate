//
//  TemperaturePicker.swift
//  Circulate
//
//  Created by Neil Pankey on 6/5/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import UIKit
import Circulate
import ReactiveCocoa

@IBDesignable public final class IntPicker: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBInspectable public var min: Int = 0
    @IBInspectable public var max: Int = 1

    public var value: Int {
        return self.selectedRowInComponent(0) + min
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)

        delegate = self
        dataSource = self
    }

    public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return max - min + 1
    }

    public func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return toString(min + row)
    }
}

public final class TemperaturePicker: UIViewController {

    public var device: AnovaDevice?

    @IBOutlet weak var degreesPicker: IntPicker!

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    public override func viewDidLoad() {
        doneButton.addTarget(self, action: "done", forControlEvents: .TouchUpInside)
        cancelButton.addTarget(self, action: "close", forControlEvents: .TouchUpInside)
    }

    public func done() {
        // TODO
//        device!.setTemperatureDegrees(Float(degreesPicker.value))
//            |> start(next: { _ in
                self.close()
//            })
    }

    public func close() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
