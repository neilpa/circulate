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
    private let central: CBCentralManager
    private let delegate: CentralManagerDelegate

    public init() {
        let queue = dispatch_queue_create("me.neilpa.circulate.CentralManager", DISPATCH_QUEUE_SERIAL)
        central = CBCentralManager(delegate: nil, queue: queue)
        delegate = CentralManagerDelegate(central: central)
    }

    private let _scanDisposable = SerialDisposable()

    public func scan(services: [CBUUID]?) -> SignalProducer<ScanResult, NoError> {
        return SignalProducer { observer, disposable in
            // Interrupt any previous scan call since we can only have one oustanding. This
            // is a limitation of CBCentralManager since it updates it scan parameters in-place.
            self._scanDisposable.innerDisposable = disposable

            self.delegate.scanSignal.observe(observer)

            self.central.scanForPeripheralsWithServices(services, options: nil)

            disposable.addDisposable {
                self.central.stopScan()
            }
        }
        // TODO There are some lifetime issues somehwere I need to track down that this "fixes"
        |> logEvents("scan:")
    }

    // TODO Connect and disconnec that checks current state
    public func connect(peripheral: CBPeripheral) -> SignalProducer<Peripheral, NSError> {
        return SignalProducer { observer, disposable in
            self.delegate.connectSignal
                |> promoteErrors(NSError.self)
                |> filter { $0.0 == peripheral }
                |> take(1)
                |> tryMap { periph, err in
                    if let error = err {
                        return .failure(error)
                    } else {
                        return .success(Peripheral(central: self.central, peripheral: periph))
                    }
                }
                |> observe(observer)

            self.central.connectPeripheral(peripheral, options: nil)
        }
        |> logEvents("connect:")
    }
}
