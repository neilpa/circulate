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

@end
