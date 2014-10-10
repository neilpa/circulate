//
//  ViewController.m
//  Circulate
//
//  Created by Neil Pankey on 9/17/14.
//  Copyright (c) 2014 Neil Pankey. All rights reserved.
//

#import "ViewController.h"

#import "AnovaClient.h"
#import "AnovaDevice.h"

@interface ViewController () <AnovaClientDelegate, AnovaDeviceDelegate>
@property (nonatomic, readonly) AnovaClient* client;
@property (nonatomic, readonly) AnovaDevice* device;

@property (weak, nonatomic) IBOutlet UITextField *command;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _client = [[AnovaClient alloc] initWithDelegate:self];
}

- (void) anovaClient:(AnovaClient*)client discoveredDevice:(AnovaDevice*)device
{
    _device = device;
    device.delegate = self;
    [device connect];
}

- (void) anovaDeviceConnected:(AnovaDevice *)device
{
    NSLog(@"Connected");
}

- (void) anovaDevice:(AnovaDevice*)device connectionFailed:(NSError*)error
{
    NSLog(@"Failed connection");
}

- (void) anovaDeviceDisconnected:(AnovaDevice*)device error:(NSError*)error
{
    NSLog(@"Disconnected %@", error);
}

- (void) anovaDevice:(AnovaDevice*)device response:(NSString*)response
{
    NSLog(@"Response: %@", response);
}

- (IBAction)_onClick:(id)sender
{
    [self.device sendCommand:self.command.text];
}

@end
