//
//  AnovaClient.h
//  Circulate
//
//  Created by Neil Pankey on 9/17/14.
//  Copyright (c) 2014 Neil Pankey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnovaDevice;
@protocol AnovaClientDelegate;

@interface AnovaClient : NSObject

- (instancetype) initWithDelegate:(id<AnovaClientDelegate>)delegate;

@end

@protocol AnovaClientDelegate<NSObject>

- (void) anovaClient:(AnovaClient*)client discoveredDevice:(AnovaDevice*)device;

@end
