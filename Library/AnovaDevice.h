//
//  AnovaDevice.h
//  Circulate
//
//  Created by Neil Pankey on 9/17/14.
//  Copyright (c) 2014 Neil Pankey. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AnovaDeviceDelegate;

@interface AnovaDevice : NSObject

@property (nonatomic, readwrite) id<AnovaDeviceDelegate> delegate;

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* identifier;

// TODO Turn these into a block based API
- (void) connect;
- (void) disconnect;

- (void) getTemperatureUnit;
- (void) setTemperatureUnit:(NSString*)unit;

- (void) getCurrentTemperature;
- (void) getTargetTemperature;
- (void) setTargetTemperature:(float)temp;

- (void) getTemperatureHistory;

- (void) getDeviceStatus;
- (void) startDevice;
- (void) stopDevice;

- (void) getTimerStatus;
- (void) setTimer:(int)minutes;
- (void) startTimer;
- (void) stopTimer;

- (void) getCalibrationFactor;
- (void) setCalibrationFactor:(float)factor;

- (void) setDeviceName:(NSString*)name;
- (void) getDate;
- (void) setDate:(int)year month:(int)month day:(int)day hour:(int)hour minute:(int)minute;

- (void) setColor:(int)red green:(int)green blue:(int)blue;


// TODO program and few remaining commands

- (void) sendCommand:(NSString*)command;

@end

@protocol AnovaDeviceDelegate <NSObject>

- (void) anovaDeviceConnected:(AnovaDevice*)device;
- (void) anovaDevice:(AnovaDevice*)device connectionFailed:(NSError*)error;
- (void) anovaDeviceDisconnected:(AnovaDevice*)device error:(NSError*)error;

- (void) anovaDevice:(AnovaDevice*)device response:(NSString*)response;

@end