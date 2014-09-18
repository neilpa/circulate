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

@end

@protocol AnovaDeviceDelegate <NSObject>

@optional
- (void) anovaDeviceConnected:(AnovaDevice*)device;
- (void) anovaDevice:(AnovaDevice*)device connectionFailed:(NSError*)error;
- (void) anovaDeviceDisconnected:(AnovaDevice*)device;

@end