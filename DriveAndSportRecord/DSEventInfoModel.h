//
//  DSEventInfoModel.h
//  DriveAndSportRecord
//
//  Created by Tristan on 2017/9/1.
//  Copyright © 2017年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSDefines.h"

@interface DSEventInfoModel : NSObject

@property(nonatomic, assign) NSInteger eventId;
@property(nonatomic, assign) NSInteger userId;
@property(nonatomic, assign) NSInteger eventDate;
@property(nonatomic, assign) EventType eventType;
@property(nonatomic, assign) EventValue eventValue;
@property(nonatomic, assign) long long timetag;
@property(nonatomic, strong) NSString *decript;

@end
