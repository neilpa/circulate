//
//  BluetoothClient.swift
//  Circulate
//
//  Created by Neil Pankey on 5/26/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

public final class BluetoothClient: NSObject, CBCentralManagerDelegate {
    private let central: CBCentralManager

    private let scanSignal: Signal<CBPeripheral, NoError>
    private let scanSink: Signal<CBPeripheral, NoError>.Observer

    private let connectSignal: Signal<(CBPeripheral, ConnectionStatus), NoError>
    private let connectSink: Signal<(CBPeripheral, ConnectionStatus), NoError>.Observer

    public let status: PropertyOf<CBCentralManagerState>
    private let _status: MutableProperty<CBCentralManagerState>

    public override init() {
        (scanSignal, scanSink) = Signal<CBPeripheral, NoError>.pipe()
        (connectSignal, connectSink) = Signal<(CBPeripheral, ConnectionStatus), NoError>.pipe()

        _status = MutableProperty(.Unknown)
        status = PropertyOf(_status)

        // This wonky initialization enables us to declare central as immutable and non-optional.
        let queue = dispatch_queue_create("me.neilpa.circulate.client", DISPATCH_QUEUE_SERIAL)
        central = CBCentralManager(delegate: nil, queue: queue)
        super.init()
        central.delegate = self
    }

    // TODO Should be the service IDs for Input, and probable a timeout
    public private(set) lazy var scan: Action<(), CBPeripheral, NoError> = Action { input in
        println("") // WTF why does this magically fix scanning?

        return SignalProducer { observer, disposable in
            self.scanSignal.observe(observer)

            self.central.scanForPeripheralsWithServices(nil, options: nil)
            disposable.addDisposable {
                self.central.stopScan()
            }
        }
    }

    public func connect(peripheral: CBPeripheral) -> SignalProducer<BluetoothDevice, NoError> {
        return SignalProducer { observer, disposable in
            let signal = self.connectSignal
                |> filter { $0.0 == peripheral  }
                |> map { BluetoothDevice(peripheral: $0.0, central: self.central) }

            disposable += signal.observe(observer)
            self.central.connectPeripheral(peripheral, options: nil)
        }
        |> on(next: println)
    }

    // MARK: CBCentralManagerDelegate
    // Sadly all of these have to be public

    public func centralManagerDidUpdateState(central: CBCentralManager!) {
        _status.value = central.state
    }

    public func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("scanned \(peripheral)")
        sendNext(scanSink, peripheral)
    }

    public func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("connected")
        sendNext(connectSink, (peripheral, .Connected))
    }

    public func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("failed")
        sendNext(connectSink, (peripheral, .Error(error)))
    }

    public func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("disconnected")
        sendNext(connectSink, (peripheral, .Disconnected(error)))
    }

}

