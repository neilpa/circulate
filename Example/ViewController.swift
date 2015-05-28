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

public class ProducerDataSource: NSObject, UICollectionViewDataSource {
    private let _count: () -> Int
    private let _cell: (UICollectionView, NSIndexPath) -> UICollectionViewCell
    private let _attach: (UICollectionView) -> ()

    public init<T, E>(_ producer: SignalProducer<T, E>, _ configure: (UICollectionView, NSIndexPath, T) -> UICollectionViewCell) {
        var items: [T] = []

        _count = { _ in items.count }
        _cell = { configure($0, $1, items[$1.item]) }
        _attach = { collectionView in
            producer
                |> observeOn(UIScheduler())
                |> start(next: { item in
                    items.append(item)

                    let path = NSIndexPath(forItem: items.count - 1, inSection: 0)
                    collectionView.insertItemsAtIndexPaths([path])
                })

            // HACK - avoids a compiler crash
            return
        }
    }

    public func attach(collectionView: UICollectionView) {
        collectionView.dataSource = self
        _attach(collectionView)
    }

    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _count()
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return _cell(collectionView, indexPath)
    }
}

public class DeviceCell: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!

    public var device: BluetoothDevice? {
        didSet {
            nameLabel.text = device?.identifier
        }
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private var client: BluetoothClient?
    private var dataSource: ProducerDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        client = BluetoothClient()
        let devices = client!.scan.apply(())
        dataSource = ProducerDataSource(devices) { view, path, device in
            let cell = view.dequeueReusableCellWithReuseIdentifier("Device", forIndexPath: path) as! DeviceCell
            cell.device = device
            return cell
        }
        dataSource?.attach(collectionView)
    }

}

