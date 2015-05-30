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

// Proxy and delegate for `CBCentralManager` exposing signals for the `CBCentralManagerDelegate` methods.
internal final class CentralManagerProxy: NSObject, CBCentralManagerDelegate {
    private let central: CBCentralManager

    let scanSignal: Signal<CBPeripheral, NoError>
    private let _scanSink: Signal<CBPeripheral, NoError>.Observer

    let connectionSignal: Signal<(CBPeripheral, ConnectionStatus), NoError>
    private let _connectionSink: Signal<(CBPeripheral, ConnectionStatus), NoError>.Observer

    let status: PropertyOf<CBCentralManagerState>
    private let _status: MutableProperty<CBCentralManagerState>

    required init(_ central: CBCentralManager) {
        (scanSignal, _scanSink) = Signal<CBPeripheral, NoError>.pipe()
        (connectionSignal, _connectionSink) = Signal<(CBPeripheral, ConnectionStatus), NoError>.pipe()

        _status = MutableProperty(central.state)
        status = PropertyOf(_status)

        self.central = central
        super.init()
        central.delegate = self
    }

    func scan(services: [CBUUID]!) {
        central.scanForPeripheralsWithServices(services, options: nil)
    }

    func stopScan() {
        central.stopScan()
    }

    func connect(peripheral: CBPeripheral) {
        central.connectPeripheral(peripheral, options: nil)
    }

    func disconnect(peripheral: CBPeripheral) {
        central.cancelPeripheralConnection(peripheral)
    }

    func centralManagerDidUpdateState(central: CBCentralManager!) {
        _status.value = central.state
    }

    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        sendNext(_scanSink, peripheral)
    }

    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        sendNext(_connectionSink, (peripheral, .Connected))
    }

    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        sendNext(_connectionSink, (peripheral, .Error(error)))
    }

    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        sendNext(_connectionSink, (peripheral, .Disconnected(error)))
    }
}
