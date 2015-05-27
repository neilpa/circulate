//
//  BluetoothClient.swift
//  Circulate
//
//  Created by Neil Pankey on 5/26/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import CoreBluetooth
import ReactiveCocoa

public extension CBCentralManager {

    internal final class Discovery:  NSObject, CBCentralManagerDelegate {
        let sink: Signal<CBPeripheral, NoError>.Observer
        var central: CBCentralManager?

        internal init(sink: Signal<CBPeripheral, NoError>.Observer) {
            self.sink = sink
            super.init()

            let queue = dispatch_queue_create("me.neilpa.circulate.client", DISPATCH_QUEUE_SERIAL)
            central = CBCentralManager(delegate: self, queue: queue)
        }

        deinit {
            central?.stopScan()
        }

        internal func centralManagerDidUpdateState(central: CBCentralManager!) {
        }

        internal func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
            sendNext(sink, peripheral)
        }
    }


    public static func discoverPeripherals(services: [CBUUID]) -> SignalProducer<CBPeripheral, NoError> {
        return SignalProducer { observer, disposable in
            let discovery = Discovery(sink: observer)

            disposable.addDisposable {

            }
        }
    }
}



public final class BluetoothDevice: NSObject, CBPeripheralDelegate {
    private let peripheral: CBPeripheral
    private let proxy: CentralProxy

    public lazy var connect: Action<(), (), NoError> = Action { _ in
        return .never
    }

    public lazy var disconnect: Action<(), (), NoError> = Action { _ in
        return .never
    }

    internal init(peripheral: CBPeripheral, proxy: CentralProxy) {
        self.peripheral = peripheral
        self.proxy = proxy
    }
}

public final class BluetoothClient {
//    private let scanSignal: Signal<CBPeripheral, NoError>
//    private let scanSink: Signal<SignalProducer<CBPeripheral, NoError>, NoError>.Observer

    private var proxy = CentralProxy()

    // TODO Should be the service IDs for Input
    public lazy var scan: Action<(), BluetoothDevice, NoError> = Action {
        return SignalProducer { observer, disposable in
            println("Scanning")
            // TODO Figure out a better structure for this
            //      need to set this as "latest" whenever
            //      could probably do some flatten(.Latest) trick
            self.proxy.scanSignal
                |> map {
                    return BluetoothDevice(peripheral: $0, proxy: self.proxy)
                }
                |> observe(observer)

            self.proxy.scan()
            disposable.addDisposable {
                self.proxy.central.stopScan()
            }
        }
    }

    public init() {
    }
}

/// Wraps a CBCentralManger, acting as a delegate
internal final class CentralProxy:  NSObject, CBCentralManagerDelegate {
    internal let central: CBCentralManager

    internal let scanSignal: Signal<CBPeripheral, NoError>
    private let scanSink: Signal<CBPeripheral, NoError>.Observer

    // TODO Expose connection state
    internal let connectionSignal: Signal<CBPeripheral, NoError>
    private let connectionSink: Signal<CBPeripheral, NoError>.Observer

    override internal init() {
        (scanSignal, scanSink) = Signal<CBPeripheral, NoError>.pipe()
        (connectionSignal, connectionSink) = Signal<CBPeripheral, NoError>.pipe()

        let queue = dispatch_queue_create("me.neilpa.circulate.client", DISPATCH_QUEUE_SERIAL)
        central = CBCentralManager(delegate: nil, queue: queue)

        super.init()
        central.delegate = self
    }

    internal func scan() {
        central.scanForPeripheralsWithServices(nil, options: nil)
    }

    internal func centralManagerDidUpdateState(central: CBCentralManager!) {
        // TODO
    }

    internal func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println(peripheral)
        println(advertisementData)
        println(RSSI)
        sendNext(scanSink, peripheral)
    }

    internal func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        sendNext(connectionSink, peripheral)
    }

    internal func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        // TODO
    }

    internal func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        // TODO
    }
}

