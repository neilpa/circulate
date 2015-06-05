    //
//  ViewController.swift
//  Example
//
//  Created by Neil Pankey on 5/26/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import UIKit
import Circulate
import CoreBluetooth
import ReactiveCocoa
import Rex

class DeviceCell: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!

    var device: CBPeripheral? {
        didSet {
            nameLabel.text = device?.name
            uuidLabel.text = device?.identifier.UUIDString
        }
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class DeviceList: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private let central = CentralManager()
    private var dataSource: ProducerDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        let scan: SignalProducer<CBPeripheral, NoError> = central.scan(nil)
            |> map { peripheral, _, _ in peripheral }

//        let devices: SignalProducer<AnovaDevice, NSError> = central.scan(nil)
//            |> promoteErrors(NSError.self)
//            |> map {
//                return self.central.connect($0)
//            }
//            |> flatten(.Merge)
//            |> map {
//                subscribe($0)
//            }
//            |> flatten(.Merge)
////            |> timeoutAfter(2, withEvent: .Completed, onScheduler: QueueScheduler.mainQueueScheduler)
////            |> logEvents("devices:")

        dataSource = ProducerDataSource(scan) { view, path, peripheral in
            let cell = view.dequeueReusableCellWithReuseIdentifier("Device", forIndexPath: path) as! DeviceCell
            cell.device = peripheral
            return cell
        }
        dataSource?.attach(collectionView)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let cell = sender as? DeviceCell, let device = cell.device {
                let navController = segue.destinationViewController as! UINavigationController
                let deviceController = navController.topViewController as! DeviceScreen
                deviceController.peripheral = device
                deviceController.central = central
                deviceController.navigationItem.title = device.name
            }
        }
    }
}

