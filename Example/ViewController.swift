//
//  ViewController.swift
//  Example
//
//  Created by Neil Pankey on 5/26/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Circulate

class ViewController: UIViewController {

    private var client: BluetoothClient?

    override func viewDidLoad() {
        super.viewDidLoad()

        client = BluetoothClient()
        client!.scan.apply(())
            |> start(next: println)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

