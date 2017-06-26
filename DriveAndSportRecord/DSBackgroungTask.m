//
//  DSBackgroungTask.m
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/10.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

#import "DSBackgroungTask.h"
#import "DSRecordConfig.h"
#import "DSDefines.h"

@interface DSBackgroungTask () <CLLocationManagerDelegate>

/**
 定位管理器
 */
@property (nonatomic, strong) CLLocationManager *locationManager;
/**
 陀螺仪管理器
 */
@property (nonatomic, strong) CMMotionManager *motionManager;
/**
 感应器类型
 */
@property (nonatomic, assign) AccelerometerType accelerometerType;
/**
 感应器监测点
 */
@property (nonatomic, assign) CMAcceleration acc;
/**
 上一个监测点的x
 */
@property (nonatomic, assign) float px;
/**
 上一个监测点的y
 */
@property (nonatomic, assign) float py;
/**
 上一个监测点的z
 */
@property (nonatomic, assign) float pz;
/**
 用以判定走步的值
 */
@property (nonatomic, assign) int pedometer;
/**
 最近一次记录的时间
 */
@property (nonatomic, assign) NSTimeInterval lastSaveAllCacheDataTime;



@property (nonatomic, assign) NSInteger userId;

@end

@implementation DSBackgroungTask

#pragma mark - Life Cycle

- (instancetype)initWithUserid:(NSInteger)userId {
    if (self = [super init]) {
        _userId = userId;
        _locationManager = [[CLLocationManager alloc] init];
        _motionManager = [[CMMotionManager alloc] init];
        _pedometer = 0;
        [self configLocation];
    }
    return self;
}

#pragma mark - Setter

- (void)setUserId:(NSInteger)userId {
    _userId = userId;
}


#pragma mark - ConfigLocation

- (void)configLocation {
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
        [_locationManager requestAlwaysAuthorization];
    }
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([CLLocationManager locationServicesEnabled]) {
        [_locationManager startUpdatingLocation];
    }else{
        NSLog(@"无法获取城市信息，请开启定位功能");
    }
}


#pragma mark - ConfigMotionManager

- (void)startAccelerometerSeverWithAccelerometerType:(AccelerometerType)accelerometerType {
    WEAK_SELF
    //开启感应器,感应器有两种状态1.记步状态 2.定时判断回写状态
    if (_motionManager.isAccelerometerActive && _accelerometerType == accelerometerType) {
        //已经开启，且状态相同
        return;
    } else {
        //关闭陀螺仪服务
        if ([_motionManager isAccelerometerActive]) {
            if (_accelerometerType == AccelerometerType_Custom) {
                NSLog(@"切换加速计模式，从正常模式切换到定时回写模式");
            } else {
                NSLog(@"切换加速计模式，从定时回写模式切换到正常模式");
            }
        } else {
            if (_accelerometerType == AccelerometerType_Custom) {
                NSLog(@"开启加速计，设定为正常模式");
            } else {
                NSLog(@"开启加速计，设定为定时回写模式");
            }
        }
        //切换状态
        if (_accelerometerType == AccelerometerType_Custom) {
            //计步状态
            __block float lastTimeTag = 0.f;
            _motionManager.accelerometerUpdateInterval = 1/100.f;
            if (_motionManager.accelerometerAvailable) {
                [_motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
                                                     withHandler:^(CMAccelerometerData *data,NSError *error){
                                                         //25个点取一个点
                                                         if (data.timestamp - lastTimeTag < 0.25) {
                                                             //丢弃多余的点
                                                             return ;
                                                         }
                                                         //开始取点
                                                         lastTimeTag = data.timestamp;
                                                         weakSelf.acc = data.acceleration;
                                                         
                                                         float xx = data.acceleration.x;
                                                         float yy = data.acceleration.y;
                                                         float zz = data.acceleration.z;
                                                         
                                                         float dot = (weakSelf.px * xx) + (weakSelf.py * yy) + (weakSelf.pz * zz);
                                                         //分别计算  两个向量的模
                                                         float a = ABS(sqrt(weakSelf.px * weakSelf.px + weakSelf.py * weakSelf.py + weakSelf.pz * weakSelf.pz));
                                                         float b = ABS(sqrt(xx * xx + yy * yy + zz * zz));
                                                         dot /= (a * b);
                                                         
                                                         if (dot <= 0.82) {
                                                             //成功感测到一步，动走步的可能性增加
                                                             if (weakSelf.pedometer < PEDOMETERTYPEWALK_VALUE*10) {
                                                                 weakSelf.pedometer += PEDOMETERTYPEWALK_VALUE;
                                                             }
                                                         } else {
                                                             //检测到非走步，移动走步的可能行减一
                                                             if (weakSelf.pedometer > 0) {
                                                                 weakSelf.pedometer--;
                                                             }
                                                         }
                                                         weakSelf.px = xx; weakSelf.py = yy; weakSelf.pz = zz;

                                                         
                                                     }];
            }
        } else {
            //加速计定时写回方案
            _motionManager.accelerometerUpdateInterval = 60 * 10;
            if (_motionManager.accelerometerAvailable) {
                [_motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *data,NSError *error){
                    [self saveJourneyRecordAndLogInfoWithSaveRecordTimerType:SaveRecordTimerType_Acceleration];
                }];
            }
        }
        _accelerometerType = accelerometerType;
    }
}



#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([error code] != kCLErrorLocationUnknown && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"定位出错");
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    //定位授权状态改变
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(nonnull CLLocation *)newLocation fromLocation:(nonnull CLLocation *)oldLocation {
    [self locationManager:manager newLocation:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self locationManager:manager newLocation:[locations lastObject]];
}


#pragma mark - Location Actions

- (void)locationManager:(CLLocationManager *)manager newLocation:(CLLocation *)location {
    CLLocation *newLocation = [[CLLocation alloc] initWithCoordinate:location.coordinate
                                                            altitude:location.altitude
                                                  horizontalAccuracy:location.horizontalAccuracy
                                                    verticalAccuracy:location.verticalAccuracy
                                                              course:location.course
                                                               speed:location.speed
                                                           timestamp:location.timestamp];
    
    //基础数据
    double altitude = newLocation.altitude;
    double longitude = newLocation.coordinate.longitude;
    double latitude = newLocation.coordinate.latitude;
    double horizontalAccuracy = newLocation.horizontalAccuracy;
    double verticalAccuracy = newLocation.verticalAccuracy;
    double course = newLocation.course;
    double speed = newLocation.speed;
    double timeStamp = [[NSDate date] timeIntervalSince1970];
    NSInteger journeyId = [DSRecordConfig getJourneyIdByTimeStamp:timeStamp];
    NSInteger userId = _userId;
    
    //根据当前电量判断是否开启记录功能
    float batteryLevel = [DSRecordConfig getBatteryLevel];
    if (batteryLevel < DSLOWPOWER && batteryLevel >= 0 && [UIDevice currentDevice].batteryState != UIDeviceBatteryStateCharging) {
        //低电量且不在充电
    }
    
}

#pragma mark - Record

-(void)saveJourneyRecordAndLogInfoWithSaveRecordTimerType:(SaveRecordTimerType)saveRecordTimerType {
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        return;
    }
    NSTimeInterval newTimeInterval = [[NSDate date] timeIntervalSince1970];
    float stopTime = newTimeInterval - _lastSaveAllCacheDataTime;
    if (saveRecordTimerType != SaveRecordTimerType_Force && (stopTime < 5*60 || _lastSaveAllCacheDataTime == 0)) {
        //定时写回的时间间隔为1分钟
        return;
    }
    //进入写回阶段
    _lastSaveAllCacheDataTime = [[NSDate date] timeIntervalSince1970];
    //新开行程去保留全部数据
    [NSThread detachNewThreadSelector:@selector(saveAllRecordInfo) toTarget:self withObject:nil];
}

@end
