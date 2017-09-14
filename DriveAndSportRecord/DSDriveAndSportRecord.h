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

+ (instancetype)sharedRecord;

- (BOOL)isLocationServicesEnabled;

- (BOOL)isAuthorized;

- (void)changeDS:(BOOL)value;

@end
