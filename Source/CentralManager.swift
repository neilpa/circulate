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

// Wraps a `CBCentralManager` exposing signals for the `CBCentralManagerDelegate` methods.
public final class CentralManager: NSObject, CBCentralManagerDelegate {
    private let central: CBCentralManager

    public let scanSignal: Signal<CBPeripheral, NoError>
    private let _scanSink: Signal<CBPeripheral, NoError>.Observer
    private let _scanDisposable = SerialDisposable()

    public let connectionSignal: Signal<(CBPeripheral, ConnectionStatus), NoError>
    private let _connectionSink: Signal<(CBPeripheral, ConnectionStatus), NoError>.Observer

    public let status: PropertyOf<CBCentralManagerState>
    private let _status: MutableProperty<CBCentralManagerState>

    public required init(central: CBCentralManager) {
        (scanSignal, _scanSink) = Signal<CBPeripheral, NoError>.pipe()
        (connectionSignal, _connectionSink) = Signal<(CBPeripheral, ConnectionStatus), NoError>.pipe()

        _status = MutableProperty(central.state)
        status = PropertyOf(_status)

        self.central = central
        super.init()
        central.delegate = self
    }

    public convenience override init() {
        let queue = dispatch_queue_create("me.neilpa.circulate.CentralManager", DISPATCH_QUEUE_SERIAL)
        self.init(central: CBCentralManager(delegate: nil, queue: queue))
    }

    public func scan(services: [CBUUID]) -> SignalProducer<CBPeripheral, NoError> {
        return SignalProducer { observer, disposable in
            // Interrupt any previous scan call since we can only have one oustanding. This
            // is a limitation of CBCentralManager since it updates it scan parameters in-place.
            self._scanDisposable.innerDisposable = disposable

            self.scanSignal.observe(observer)

            let services: [AnyObject]? = services.isEmpty ? nil : services
            self.central.scanForPeripheralsWithServices(services, options: nil)

            disposable.addDisposable {
                self.central.stopScan()
            }
        }
        // TODO There are some lifetime issues somehwere I need to track down that this "fixes"
        |> on(started: { println("STARTED") }, event: println, disposed: { println("DISPOSED") })
    }

    public func connect(peripheral: CBPeripheral) -> SignalProducer<ConnectionStatus, NoError> {
        return SignalProducer { observer, disposable in
            self.connectionSignal
                |> filter { $0.0 == peripheral }
                |> map { $0.1 }
                |> observe(observer)

            self.central.connectPeripheral(peripheral, options: nil)
            disposable.addDisposable {
                self.central.cancelPeripheralConnection(peripheral)
            }
        }
    }

    // MARK: CBCentralManagerDelegate
    // Sadly all of these have to be public

    public func centralManagerDidUpdateState(central: CBCentralManager!) {
        _status.value = central.state
    }

    public func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        sendNext(_scanSink, peripheral)
    }

    public func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        sendNext(_connectionSink, (peripheral, .Connected))
    }

    public func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        sendNext(_connectionSink, (peripheral, .Error(error)))
    }

    public func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        sendNext(_connectionSink, (peripheral, .Disconnected(error)))
    }
}
