//
//  ProducerDataSource.swift
//  Circulate
//
//  Created by Neil Pankey on 5/28/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import UIKit
import ReactiveCocoa

public final class ProducerDataSource: NSObject, UICollectionViewDataSource {
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
