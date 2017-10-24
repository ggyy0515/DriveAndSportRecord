//
//  DSDriveAndSportRecord.h
//  DriveAndSportRecord
//
//  Created by Tristan on 2017/9/13.
//  Copyright © 2017年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString *const DSNotificationNameAllJouneryDidSaved;

@interface DSDriveAndSportRecord : NSObject
//目标的经纬度
@property (nonatomic, assign) double desLongitude;
@property (nonatomic, assign) double desLatitude;

+ (instancetype)sharedRecord;

- (CLLocationManager *)locationManager;

- (BOOL)isLocationServicesEnabled;

- (BOOL)isAuthorized;

- (void)changeDS:(BOOL)value;

@end
