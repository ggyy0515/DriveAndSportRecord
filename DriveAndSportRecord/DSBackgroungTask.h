//
//  DSBackgroungTask.h
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/10.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

#import "DSDefines.h"

@class DSGlobals;
@class DSJourneyRecordModel;
@class DSDatabaseService;


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
- (void)saveTravelRecordAndLogInfoWithSaveRecordTimerType:(SaveRecordTimerType)saveRecordTimerType;
- (void)startAllServer;
- (void)stopAllServer;

/**
 定位管理器
 */
@property (nonatomic, strong) CLLocationManager *locationManager;
/**
 是否开启CM服务
 */
@property (nonatomic, assign) BOOL isCMServerActivity;
@property (nonatomic, assign) CallState callState;
@property (nonatomic, assign) CallState currentCallState;
@property (nonatomic, assign) BOOL lowEnergy;
@property (nonatomic, strong) NSMutableArray *eventArray;
@property (nonatomic, assign) BOOL isLocationServerStarted;
@property (nonatomic, strong) DSJourneyRecordModel *journeyRecord;
@property (nonatomic, assign) PedometerType currentPedometerType;
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, assign) __block CMMotionActivityConfidence confidence;
@property (nonatomic, assign) NSTimeInterval  stopTimeInterval;
@property (nonatomic, strong) DSGlobals *globals;
@property (nonatomic, strong) NSMutableArray *recordArray;
@property (nonatomic, assign) int previouAbnormalType;
@property (nonatomic, assign) NSTimeInterval currentInterval, previousInterval;
@property (nonatomic, strong) NSMutableArray *journeyArray;
@property (nonatomic, strong) DSDatabaseService *databaseService;
@property (nonatomic, strong) CMMotionActivityManager *activityManager;

@end
