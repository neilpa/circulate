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
import CoreBluetooth

class DeviceCell: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!

    var device: BluetoothDevice? {
        didSet {
            nameLabel.text = device?.name
            uuidLabel.text = device?.identifier
        }
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class DeviceList: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private var client: BluetoothClient?
    private var dataSource: ProducerDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        let client = BluetoothClient()
        self.client = client

        let devices = client.scan.apply(())
            |> catch { _ in SignalProducer.empty }
            |> flatMap(.Latest) {
                client.connect($0)
            }

        dataSource = ProducerDataSource(devices) { view, path, device in
            let cell = view.dequeueReusableCellWithReuseIdentifier("Device", forIndexPath: path) as! DeviceCell
            cell.device = device
            return cell
        }
        dataSource?.attach(collectionView)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let cell = sender as? DeviceCell, let device = cell.device {
                let navController = segue.destinationViewController as! UINavigationController
                let deviceController = navController.topViewController as! DeviceScreen
                deviceController.device = device
                deviceController.navigationItem.title = device.name
            }
        }
    }
}

