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

    public override init() {
        (scanSignal, scanSink) = Signal<CBPeripheral, NoError>.pipe()
        (connectSignal, connectSink) = Signal<CBPeripheral, NoError>.pipe()

        let queue = dispatch_queue_create("me.neilpa.circulate.client", DISPATCH_QUEUE_SERIAL)
        central = CBCentralManager(delegate: nil, queue: queue)

        super.init()
        central.delegate = self
    }

    // TODO Should be the service IDs for Input
    public lazy var scan: Action<(), BluetoothDevice, NoError> = Action { input in
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

    public func centralManagerDidUpdateState(central: CBCentralManager!) {
        // TODO
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

public final class BluetoothDevice: NSObject, CBPeripheralDelegate {
    private let peripheral: CBPeripheral
    private let central: CBCentralManager

    public lazy var connect: Action<(), (), NoError> = Action { _ in
        return .never
    }

    public lazy var disconnect: Action<(), (), NoError> = Action { _ in
        return .never
    }

    internal init(peripheral: CBPeripheral, central: CBCentralManager) {
        self.peripheral = peripheral
        self.central = central
    }
}