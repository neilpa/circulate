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

    private let connectSignal: Signal<CBPeripheral, NoError>
    private let connectSink: Signal<CBPeripheral, NoError>.Observer

    public let status: PropertyOf<CBCentralManagerState>
    private let _status: MutableProperty<CBCentralManagerState>

    public override init() {
        (scanSignal, scanSink) = Signal<CBPeripheral, NoError>.pipe()
        (connectSignal, connectSink) = Signal<CBPeripheral, NoError>.pipe()

        _status = MutableProperty(.Unknown)
        status = PropertyOf(_status)

        // This wonky initialization enables us to declare central as immutable and non-optional.
        let queue = dispatch_queue_create("me.neilpa.circulate.client", DISPATCH_QUEUE_SERIAL)
        central = CBCentralManager(delegate: nil, queue: queue)
        super.init()
        central.delegate = self
    }

    // TODO Should be the service IDs for Input
    public private(set) lazy var scan: Action<(), BluetoothDevice, NoError> = Action { input in
        return SignalProducer { observer, disposable in
            println("Scanning")
            self.scanSignal
                |> map {
                    return BluetoothDevice(peripheral: $0, central: self.central)
                }
                |> observe(observer)

            self.central.scanForPeripheralsWithServices(nil, options: nil)
            disposable.addDisposable {
                self.central.stopScan()
            }
        }
    }

    // MARK: CBCentralManagerDelegate
    // Sadly all of these have to be public

    public func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("\(central.state)")
        _status.value = central.state
    }

    public func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println(peripheral)
        println(advertisementData)
        println(RSSI)
        sendNext(scanSink, peripheral)
    }

    public func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        sendNext(connectSink, peripheral)
    }

    public func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        // TODO
    }

    public func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        // TODO
    }

}

