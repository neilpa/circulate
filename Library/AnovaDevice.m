//
//  AnovaDevice.m
//  Circulate
//
//  Created by Neil Pankey on 9/17/14.
//  Copyright (c) 2014 Neil Pankey. All rights reserved.
//

#import "AnovaDevice+Lib.h"

@import CoreBluetooth;

@interface AnovaDevice()  <CBPeripheralDelegate>
@property (nonatomic, readonly) CBCentralManager* central;
@property (nonatomic, readonly) CBPeripheral* peripheral;
@end

@implementation AnovaDevice

- (instancetype) initWithCentral:(CBCentralManager*)central peripheral:(CBPeripheral*)peripheral
{
    if (self = [super init]) {
        _central = central;
        _peripheral = peripheral;
        peripheral.delegate = self;
    }
    return self;
}

- (void) connect
{
    [self.central connectPeripheral:self.peripheral options:nil];
}

- (void) disconnect
{
    [self.central cancelPeripheralConnection:self.peripheral];
}

#pragma mark Protocol

// TODO implement the bluetooth protocol methods

#pragma mark Library

- (void) peripheralConnected
{
    // TODO Enumerate characteristics
    [self.delegate anovaDeviceConnected:self];

    [self.peripheral discoverServices:nil];
}

#pragma mark CBPeripheralDelegate

- (void) peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
    for (CBService* service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"ffe0"]]) {
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
}

// Invoked when you discover the characteristics of a specified service.
- (void) peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"ffe1"]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void) peripheral:(CBPeripheral*)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
    // Actually establish the connection with the device
    NSData* data = [@"\r" dataUsingEncoding:NSASCIIStringEncoding];
    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}


- (void) peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
    NSLog(@"%@", characteristic.value);
    // TODO Handle the response from the device
}

@end
