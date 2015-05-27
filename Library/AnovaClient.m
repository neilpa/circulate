//
//  AnovaClient.m
//  Circulate
//
//  Created by Neil Pankey on 9/17/14.
//  Copyright (c) 2014 Neil Pankey. All rights reserved.
//

#import "AnovaClient.h"
#import "AnovaDevice+Lib.h"

@import CoreBluetooth;

@interface AnovaClient() <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, readonly) CBCentralManager* central;
@property (nonatomic, readonly) id<AnovaClientDelegate> delegate;

@property (nonatomic, readonly) NSMutableDictionary* devices;
@end

@implementation AnovaClient

- (instancetype) initWithDelegate:(id<AnovaClientDelegate>)delegate
{
    if (self = [super init]) {
        _central = [[CBCentralManager alloc] initWithDelegate:nil queue:NULL];
        self.central.delegate = self;
        _delegate = delegate;
        _devices = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) centralManagerDidUpdateState:(CBCentralManager*)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"Scanning");
        NSArray* service = @[[CBUUID UUIDWithString:@"ffe0"]];
        [central scanForPeripheralsWithServices:service options:nil];
    }
}

- (void) centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI
{
    // Keep the device alive
    AnovaDevice* device = [[AnovaDevice alloc] initWithCentral:central peripheral:peripheral];
    self.devices[peripheral.identifier] = device;

    [self.delegate anovaClient:self discoveredDevice:device];
}

- (void) centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral
{
    AnovaDevice* device = self.devices[peripheral.identifier];
    [device peripheralConnected];
}

- (void) centralManager:(CBCentralManager*)central didFailToConnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error
{
    AnovaDevice* device = self.devices[peripheral.identifier];
    [device.delegate anovaDevice:device connectionFailed:error];
}

- (void) centralManager:(CBCentralManager*)central didDisconnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error
{
    AnovaDevice* device = self.devices[peripheral.identifier];
    [device.delegate anovaDeviceDisconnected:device error:error];
}

@end
