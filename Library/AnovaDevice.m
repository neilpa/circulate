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

- (void) getTemperatureUnit
{
    [self sendCommand:@"read unit"];
}

- (void) setTemperatureUnit:(NSString*)unit
{
    [self sendCommand:[NSString stringWithFormat:@"set unit %@", unit]];
}

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

- (void) getTemperatureHistory
{
    [self sendCommand:@"read data"];
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

- (void) getTimerStatus
{
    [self sendCommand:@"read timer"];
}

- (void) setTimer:(int)minutes
{
    [self sendCommand:[NSString stringWithFormat:@"set timer %i", minutes]];
}

- (void) startTimer
{
    [self sendCommand:@"start time"];
}

- (void) stopTimer
{
    [self sendCommand:@"stop time"];
}

- (void) getCalibrationFactor
{
    [self sendCommand:@"read cal"];
}

- (void) setCalibrationFactor:(float)factor
{
    [self sendCommand:[NSString stringWithFormat:@"cal %0.1f", factor]];
}

- (void) setDeviceName:(NSString*)name
{
    [self sendCommand:[NSString stringWithFormat:@"set name %@", name]];
}

- (void) getDate
{
    [self sendCommand:@"read date"];
}

- (void) setDate:(int)year month:(int)month day:(int)day hour:(int)hour minute:(int)minute
{
    [self sendCommand:[NSString stringWithFormat:@"set date %i %i %i %i %i", year, month, day, hour, minute]];
}

#pragma mark Raw command

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
    // TODO Valid for sending commands now
}


- (void) peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
    // TODO Make this not suck
    NSString* response = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding];
    [self.delegate anovaDevice:self response:response];
}

@end
