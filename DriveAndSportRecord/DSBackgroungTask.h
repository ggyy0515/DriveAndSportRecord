//
//  DSBackgroungTask.h
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/10.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    AccelerometerType_Custom = 1,       //记步状态
    AccelerometerType_Timer = 2,        //定时写回
}AccelerometerType;

typedef enum {
    SaveRecordTimerType_Location = 1,
    SaveRecordTimerType_M7 = 2,
    SaveRecordTimerType_Acceleration = 3,
    SaveRecordTimerType_Force = 4,
    SaveRecordTimerType_IBeacon = 5,
} SaveRecordTimerType;

@interface DSBackgroungTask : NSObject


/**
 初始化方法
 
 @param userId userId
 @return 实例对象
 */
- (instancetype)initWithUserid:(NSInteger)userId;

/**
 设置userId
 
 @param userId userId
 */
- (void)setUserId:(NSInteger)userId;

@end
