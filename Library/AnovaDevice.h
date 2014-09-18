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

- (void) connect;
- (void) disconnect;

- (void) getCurrentTemperature;
- (void) getTargetTemperature;
- (void) setTargetTemperature:(float)temp;

- (void) getDeviceStatus;
- (void) startDevice;
- (void) stopDevice;

// TODO implement more

@end

@protocol AnovaDeviceDelegate <NSObject>

- (void) anovaDeviceConnected:(AnovaDevice*)device;
- (void) anovaDevice:(AnovaDevice*)device connectionFailed:(NSError*)error;
- (void) anovaDeviceDisconnected:(AnovaDevice*)device;

- (void) anovaDevice:(AnovaDevice*)device response:(NSString*)response;

@end