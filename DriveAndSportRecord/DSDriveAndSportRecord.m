//
//  DSDriveAndSportRecord.m
//  DriveAndSportRecord
//
//  Created by Tristan on 2017/9/13.
//  Copyright © 2017年 Tristan. All rights reserved.
//

#import "DSDriveAndSportRecord.h"
#import "DSDefines.h"
#import "DSGlobals.h"


NSString *const DSNotificationNameAllJouneryDidSaved = @"DSNotificationNameAllJouneryDidSaved";

@interface DSDriveAndSportRecord () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation DSDriveAndSportRecord

#pragma mark - Life Cycle

+ (instancetype)sharedRecord {
    static DSDriveAndSportRecord *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc {
    _locationManager.delegate = nil;
}

#pragma mark - Getter

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
        [_locationManager requestAlwaysAuthorization];
    }
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    return _locationManager;
}

#pragma mark - Public

- (BOOL)isLocationServicesEnabled {
    BOOL locationServicesEnabledInstancePropertyAvailable = [self.locationManager respondsToSelector:@selector(locationServicesEnabled)]; // iOS 3.x
    BOOL locationServicesEnabledClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(locationServicesEnabled)]; // iOS 4.x
    
    if (locationServicesEnabledClassPropertyAvailable) { // iOS 4.x
        return [CLLocationManager locationServicesEnabled];
    } else if (locationServicesEnabledInstancePropertyAvailable) { // iOS 2.x, iOS 3.x
        return [(id)self.locationManager locationServicesEnabled];
    } else {
        return NO;
    }
}

- (BOOL)isAuthorized {
    NSUInteger authStatus = [CLLocationManager authorizationStatus];
    return (authStatus == kCLAuthorizationStatusAuthorizedAlways) || (authStatus == kCLAuthorizationStatusNotDetermined);
}

//手动改变DS服务状态
- (void)changeDS:(BOOL)value {
    [DSGlobals sharedGlobals].canAutoStartLocationServerOnBack = value;
}


#pragma mark - Private



@end
