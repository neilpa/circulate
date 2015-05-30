//
//  CentralManager.swift
//  Circulate
//
//  Created by Neil Pankey on 5/29/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa
import Rex

public final class CentralManager {
    private let proxy: CentralManagerProxy

    public init() {
        let queue = dispatch_queue_create("me.neilpa.circulate.CentralManager", DISPATCH_QUEUE_SERIAL)
        proxy = CentralManagerProxy(CBCentralManager(delegate: nil, queue: queue))
    }

    private let _scanDisposable = SerialDisposable()

    public func scan(services: [CBUUID]) -> SignalProducer<CBPeripheral, NoError> {
        return SignalProducer { observer, disposable in
            // Interrupt any previous scan call since we can only have one oustanding. This
            // is a limitation of CBCentralManager since it updates it scan parameters in-place.
            self._scanDisposable.innerDisposable = disposable

            self.proxy.scanSignal.observe(observer)

            let services: [CBUUID]? = services.isEmpty ? nil : services
            self.proxy.scan(services)

            disposable.addDisposable {
                self.proxy.stopScan()
            }
        }
        // TODO There are some lifetime issues somehwere I need to track down that this "fixes"
        |> on(started: { println("STARTED") }, event: println, disposed: { println("DISPOSED") })
    }

    public func connect(peripheral: CBPeripheral) -> SignalProducer<ConnectionStatus, NoError> {
        return SignalProducer { observer, disposable in
            self.proxy.connectionSignal
                |> filter { $0.0 == peripheral }
                |> map { $0.1 }
                |> observe(observer)

            self.proxy.connect(peripheral)
            disposable.addDisposable {
                self.proxy.disconnect(peripheral)
            }
        }
    }
}
