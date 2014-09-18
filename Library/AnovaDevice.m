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
@property (nonatomic, readonly) CBCharacteristic* characteristic;
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

- (void) getCurrentTemperature
{
    [self sendCommand:@"read temp"];
}

- (void) getTargetTemperature
{
    [self sendCommand:@"read set temp"];
}

- (void) setTargetTemperature:(float)temp
{
    [self sendCommand:[NSString stringWithFormat:@"set temp %0.1f", temp]];
}

- (void) getDeviceStatus
{
    [self sendCommand:@"status"];
}

- (void) startDevice
{
    [self sendCommand:@"start"];
}

- (void) stopDevice
{
    [self sendCommand:@"stop"];
}

- (void) sendCommand:(NSString*)command
{
    NSData* data = [[command stringByAppendingString:@"\r"] dataUsingEncoding:NSASCIIStringEncoding];
    [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithoutResponse];
}

#pragma mark Library

- (void) peripheralConnected
{
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

- (void) peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"ffe1"]]) {
            _characteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            break;
        }
    }
}

- (void) peripheral:(CBPeripheral*)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
    // Actually establish the connection with the device
//    [self getDeviceStatus];
//    [self setTargetTemperature:65];
//    [self getTargetTemperature];
//    [self getCurrentTemperature];
//    [self stopDevice];
//    [self startDevice];
//    [self sendCommand:@"read timer"];
//    [self sendCommand:@"stop timer"];
//    [self sendCommand:@"status timer"];
//    [self sendCommand:@"status"];
    [self sendCommand:@"read unit"];
//    [self sendCommand:@"set unit f"];
}


- (void) peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
    // TODO Make this not suck
    NSString* response = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding];
    [self.delegate anovaDevice:self response:response];
}

@end
