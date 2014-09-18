//
//  AnovaDevice+Lib.m
//  Circulate
//
//  Created by Neil Pankey on 9/17/14.
//  Copyright (c) 2014 Neil Pankey. All rights reserved.
//

#import "AnovaDevice.h"

@import CoreBluetooth;

@interface AnovaDevice(Lib)

- (instancetype) initWithCentral:(CBCentralManager*)central peripheral:(CBPeripheral*)peripheral;

@end
