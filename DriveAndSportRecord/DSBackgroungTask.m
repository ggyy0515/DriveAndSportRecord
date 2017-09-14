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
#include <mach/mach.h>

#import "DSBackgroungTask.h"
#import "DSRecordConfig.h"
#import "DSDefines.h"
#import "DSEventInfoModel.h"
#import "DSJourneyRecordModel.h"
#import "DSGlobals.h"
#import "DSJourneyModel.h"
#import "DSDatabaseService.h"
#import "DSDriveAndSportRecord.h"

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
        _globals = [DSGlobals sharedGlobals];
        _databaseService = [_globals databaseService];
        
        _locationManager = [[CLLocationManager alloc] init];
        _motionManager = [[CMMotionManager alloc] init];
        _pedometer = 0;
        _eventArray = [NSMutableArray array];
        _recordArray = [NSMutableArray array];
        _journeyArray = [NSMutableArray array];
        
        _callState = CallState_Unknow;
        _isLocationServerStarted = NO;
        _isCMServerActivity = NO;
        _lowEnergy = NO;
        _currentPedometerType = PedometerType_Stop;
        
        //判断当前手机电话状态
        __weak typeof(self) weakSelf = self;
        _callCenter = [[CTCallCenter alloc] init];
        _callCenter.callEventHandler = ^(CTCall* call)
        {
            if (call.callState == CTCallStateDialing) {
                weakSelf.currentCallState = CallState_CallOut;
                weakSelf.callState = CallState_CallOut;
            } else if(call.callState == CTCallStateIncoming){
                weakSelf.currentCallState = CallState_CallIn;
                weakSelf.callState = CallState_CallIn;
            } else if (call.callState == CTCallStateConnected){
                if (weakSelf.callState == CallState_CallOut) {
                    weakSelf.callState = CallState_CallOutDone;
                } else if (weakSelf.callState == CallState_CallIn){
                    weakSelf.callState = CallState_CallInDone;
                }
                weakSelf.currentCallState = CallState_Connected;
            } else if (call.callState == CTCallStateDisconnected){
                weakSelf.currentCallState = CallState_Disconnected;
            }
        };
        
        [self configLocation];
    }
    return self;
}

#pragma mark - Setter

- (void)setUserId:(NSInteger)userId {
    _userId = userId;
}

#pragma mark - Public

- (void)startAllServer {
    if (_isLocationServerStarted) {
        return;
    }
    //判断是否出低电量
    NSInteger travelId = [DSGlobals getTravelIdByTimeInterval:[[NSDate date] timeIntervalSince1970]];
    DSEventInfoModel *lastEventinfo = [_databaseService getLastLowPownerEventInfoByEventDate:travelId UserId:_userId];
    if (lastEventinfo && lastEventinfo.eventValue == EventValue_Off) {
        _lowEnergy = YES;
    } else {
        _lowEnergy = NO;
    }
    NSLog(@"开启全部服务");
    if ([CLLocationManager locationServicesEnabled]) {
        //开启加速器
        if ([CMMotionActivityManager isActivityAvailable]) {
            NSLog(@"程序启动，手机支持M7，开启M7服务");
            [self startCMStepServer];
        } else {
            [self startAccelerometerServer:AccelerometerType_Custom];
        }
        //开启定位
        NSLog(@"程序启动，开启后台定位服务");
        [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyBest];
    } else {
        NSLog(@"程序启动，但定位服务不可用");
    }
}

- (void)stopAllServer {
    NSLog(@"关闭全部服务");
    //关闭定位服务
    [self stopLocationServer];
    //关闭定位服务
    [self stopAccelerometerServer];
    //关闭CM服务
    [self stopCMStepServer];
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
        NSLog(@"后台定位出错");
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    //定位授权状态改变
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"授权定位服务");
        [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyBest];
        if (!_isCMServerActivity) {
            [self startAccelerometerServer:AccelerometerType_Custom];
        }
    }
}

//iphone2-iphone6
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(nonnull CLLocation *)newLocation fromLocation:(nonnull CLLocation *)oldLocation {
    [self locationManager:manager newLocation:newLocation];
}

//>iphone6
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
    double longitude = newLocation.coordinate.longitude;
    double latitude = newLocation.coordinate.latitude;
    double horizontalAccuracy = newLocation.horizontalAccuracy;
    double course = newLocation.course;
    double speed = newLocation.speed;
    double timeStamp = [[NSDate date] timeIntervalSince1970];
    NSInteger journeyId = [DSRecordConfig getJourneyIdByTimeStamp:timeStamp];
    NSInteger userId = _userId;
    
    //根据当前电量判断是否开启记录功能
    float batteryLevel = [DSRecordConfig getBatteryLevel];
    if (batteryLevel < DSLOWPOWER && batteryLevel >= 0 && [UIDevice currentDevice].batteryState != UIDeviceBatteryStateCharging) {
        //低电量时关闭加速器
        if (!_isCMServerActivity) {
            [self stopAccelerometerServer];
        }
        //重置电话状态
        _callState = CallState_Unknow;
        //设置低电量标志
        if (!_lowEnergy) {
            NSLog(@"电量低于20%%,不在记录数据");
            //开始进入低电量
            _lowEnergy = YES;
            //添加核心事件
            DSEventInfoModel *eventInfo = [[DSEventInfoModel alloc] init];
            eventInfo.userId            = userId;
            eventInfo.eventDate         = journeyId;
            eventInfo.eventType         = EventType_Powner;
            eventInfo.eventValue        = EventValue_Off;
            eventInfo.timetag           = timeStamp;
            eventInfo.decript           = @"电量低于20%且没有充电，停止记录";
            [_eventArray addObject:eventInfo];
            //进入低电量待机状态
            [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyKilometer];
            if (!_isCMServerActivity) {
                [self stopAccelerometerServer];
            }
        }
        return;
    } else if (batteryLevel >= DSLOWPOWER || [[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging){
        if (_lowEnergy) {
            //电量恢复
            NSLog(@"电量高于限定,恢复记录数据");
            [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyBest];
            //开始退出低电量
            _lowEnergy = NO;
            //添加核心事件
            if (batteryLevel >= DSLOWPOWER) {
                DSEventInfoModel *eventInfo     = [[DSEventInfoModel alloc] init];
                eventInfo.userId                = userId;
                eventInfo.eventDate             = journeyId;
                eventInfo.eventType             = EventType_Powner;
                eventInfo.eventValue            = EventValue_On;
                eventInfo.timetag               = timeStamp;
                eventInfo.decript               = @"电量高于20%，开始记录";
                [_eventArray addObject:eventInfo];
            } else {
                DSEventInfoModel *eventInfo     = [[DSEventInfoModel alloc] init];
                eventInfo.userId                = userId;
                eventInfo.eventDate             = journeyId;
                eventInfo.eventType             = EventType_Powner;
                eventInfo.eventValue            = EventValue_On;
                eventInfo.timetag               = timeStamp;
                eventInfo.decript               = @"手机充电，开始记录";
                [_eventArray addObject:eventInfo];
            }
            //开启加速器
            if (!_isCMServerActivity) {
                [self startAccelerometerServer:AccelerometerType_Custom];
            }
        } else {
            //wifi不启动判断(暂时不处理wifi维度)
//            if (globals.wifiNoRecord && appDelegate.networkStatus == kReachableViaWiFi) {
//                //重置电话状态
//                callState = CallState_Unknow;
//                if (!isWifi){
//                    [self addLogInfoWithLogType:type_bebug logText:@"进入wifi环境,不在记录数据"];
//                    //开始进入wifi环境
//                    isWifi = TRUE;
//                    //添加核心事件
//                    EventInfo *eventInfo = [[EventInfo alloc] init];
//                    eventInfo.userId = userId;
//                    eventInfo.eventDate = travelId;
//                    eventInfo.eventType = EventType_Wifi;
//                    eventInfo.eventValue = EventValue_Off;
//                    eventInfo.timetag = timestamp;
//                    eventInfo.decript = @"进入wifi环境，停止记录";
//                    [eventArray addObject:eventInfo];
//                    //进入wifi环境
//                    [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyKilometer];
//                    if (!isCMServerActivity) {
//                        [self stopAccelerometerServer];
//                    }
//                }
//                return;
//            }
//            else if (globals.wifiNoRecord && appDelegate.networkStatus != kReachableViaWiFi) {
//                if (isWifi) {
//                    [self addLogInfoWithLogType:type_bebug logText:@"离开wifi环境,开始记录数据"];
//                    [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyBest];
//                    isWifi = FALSE;
//                    //添加核心事件
//                    EventInfo *eventInfo = [[EventInfo alloc] init];
//                    eventInfo.userId = userId;
//                    eventInfo.eventDate = travelId;
//                    eventInfo.eventType = EventType_Wifi;
//                    eventInfo.eventValue = EventValue_On;
//                    eventInfo.timetag = timestamp;
//                    eventInfo.decript = @"离开wifi环境，开始记录";
//                    [eventArray addObject:eventInfo];
//                    //开始退出wifi环境
//                    if (!isCMServerActivity) {
//                        [self startAccelerometerServer:AccelerometerType_Custom];
//                    }
//                }
//            }
        }
    }
    
    //初始默认值
    _journeyRecord.locality = @"";
    _journeyRecord.accuracy = horizontalAccuracy;
    _journeyRecord.recordIndex = _locationManager.desiredAccuracy;
    
    //相邻两个间隔点必须间隔1秒
    if (_journeyRecord && (long)timeStamp == _journeyRecord.recordId) {
        return;
    }
    
    //与上一记录点的距离
    CLLocationDistance meters = 0;
    if (_journeyRecord.latitude > 0 && _journeyRecord.longitude > 0) {
        meters = [[[CLLocation alloc] initWithLatitude:_journeyRecord.latitude longitude:_journeyRecord.longitude] distanceFromLocation:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude]];
    }
    
    //结合当前的移动速度和记步情况判断当前是走路还是休息还是开车
    if (!_isCMServerActivity) {
        //加速计方案
        if (speed >= WALKING_SPEED) {
            //移动速度大于WALKING_SPEED只可能是开车
            if (_currentPedometerType != PedometerType_Drive) {
                NSLog(@"陀螺仪开始判断为开车");
            }
            _currentPedometerType = PedometerType_Drive;
            NSLog(@"感测到一条新记录，经加速计判定为开车");
        } else if(speed < STOP_SPEED && speed >= 0 && _pedometer > PEDOMETERTYPEWALK_VALUE){
            //速度小于WALKING_SPEED但是有明显的步行痕迹就一定是步行
            if (_currentPedometerType != PedometerType_Walk) {
                NSLog(@"陀螺仪开始判断为走路");
            }
            _currentPedometerType =  PedometerType_Walk;
            NSLog(@"感测到一条新记录，经加速计判定为走路");
        } else if(speed <= STOP_SPEED && speed >= 0 && _pedometer < PEDOMETERTYPEWALK_VALUE){
            //速度为0同时特征值很低就判断为静止
            if (_currentPedometerType != PedometerType_Stop) {
                NSLog(@"陀螺仪开始判断为静止");
            }
            _currentPedometerType =  PedometerType_Stop;
            NSLog(@"感测到一条新记录，经加速计判定为静止");
        } else if(_currentPedometerType !=  PedometerType_Drive && speed > WALKING_SPEED/3 && _pedometer < PEDOMETERTYPEWALK_VALUE){
            //步行转开车
            if (_currentPedometerType != PedometerType_Drive) {
                NSLog(@"陀螺仪开始修正为开车");
            }
            _currentPedometerType =  PedometerType_Drive;
            NSLog(@"感测到一条新记录，经加速计判定为开车");
        }
        if (meters > 100){
            if (_locationManager.desiredAccuracy != kCLLocationAccuracyBest) {
                NSLog(@"距离出现跨越恢复最佳状态");
                [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyBest];
            }
        }
    } else {
        //M7根据卫星速度修正状态
        if (_journeyRecord.valid && (speed + _journeyRecord.speed)/2 > 4 && _confidence != CMMotionActivityConfidenceHigh) {
            if (_currentPedometerType != PedometerType_Drive) {
                NSLog(@"M7根据卫星速度%f修正为开车" ,speed + _journeyRecord.speed);
            }
            _currentPedometerType = PedometerType_Drive;
        }
        if (meters > 100 || speed > WALKING_SPEED/2){
            if (_locationManager.desiredAccuracy != kCLLocationAccuracyBest) {
                NSLog(@"距离出现跨越恢复最佳状态");
                [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyBest];
            }
        }
        if (_currentPedometerType ==  PedometerType_Walk) {
            NSLog(@"感测到一条新记录，经M7判定为走路");
        } else if (_currentPedometerType ==  PedometerType_Drive){
            NSLog(@"感测到一条新记录，经M7判定为开车");
        } else if (_currentPedometerType ==  PedometerType_Stop){
            NSLog(@"感测到一条新记录，经M7判定为静止");
        }
    }
    
    //联系两点经纬度相同则可判定为静止
    if (_journeyRecord && _journeyRecord.latitude == latitude && _journeyRecord.longitude == longitude){
        _currentPedometerType = PedometerType_Stop;
    }
    
    ///非M7方案提高精度
    if (_currentPedometerType == PedometerType_Drive && _journeyRecord) {
        //连续两个开车点提高精度
        if (_journeyRecord.recordType == RecordType_Drive || _journeyRecord.recordType >= RecordType_HeavyBrake) {
            if (_locationManager.desiredAccuracy != kCLLocationAccuracyBest) {
                NSLog(@"连续二点稳定有效速度才恢复最佳状态");
                [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyBest];
            }
        }
    }
    
    //省电优化
    if ((speed <= STOP_SPEED && speed >= 0)||_currentPedometerType != PedometerType_Drive||!_journeyRecord.valid){
        //前面一个点是静止点或低速点
        NSInteger stopTimeSpan = 0;
        if (_stopTimeInterval > 0) {
            stopTimeSpan = timeStamp - _stopTimeInterval;
        }
        if(stopTimeSpan > 5*60){
            NSLog(@"蓝牙启动，距离上次返回开车点间隔大于5分钟，降低定位精度");
            [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyKilometer];
        }
        //连续两个静止点
        if (_journeyRecord.recordId && _journeyRecord.recordType == RecordType_Stop && _currentPedometerType == PedometerType_Stop) {
            //相邻静止点丢弃
            [self saveTravelRecordAndLogInfoWithSaveRecordTimerType:SaveRecordTimerType_Location];
            //保存日志
            NSLog(@"新记录点为非开车,相邻间隔点都是静止点,丢弃,速度:%f 特征值:%d", speed, _pedometer);
            //重置电话状态
            _callState = CallState_Unknow;
            return;
        }
    }
    
    //电池电量
    _journeyRecord.batteryLevel = batteryLevel;
    
    //估算卫星数
    int verticalAccuracy = [location verticalAccuracy];
    if (verticalAccuracy > 0) {
        _journeyRecord.satellite = 4;
    }
    if (horizontalAccuracy > 300 && verticalAccuracy < 0 ) {
        _journeyRecord.satellite = 2;
    }
    if (horizontalAccuracy>0 && horizontalAccuracy<60) {
        _journeyRecord.satellite = 5;
    }
    if ((horizontalAccuracy>300 && horizontalAccuracy<0)&& verticalAccuracy<0) {
        _journeyRecord.satellite = 3;
    }
    
    //检测轨迹点是否有效，默认有效
    _journeyRecord.valid = YES;
    
    //开车但前进方向和速度都为负
    if (_currentPedometerType == PedometerType_Drive && (course < 0 || speed < 0)){
        //方向角小于0当误差点丢弃
        NSLog(@"新记录为异常点,开车但方向角或速度小于0");
        _journeyRecord.valid = NO;
    }
    
    //去掉误差较大点和缓存点
    NSTimeInterval interval = [newLocation.timestamp timeIntervalSinceNow];
    if (horizontalAccuracy > HORIZONTALACCURACY) {
        NSLog(@"新记录为误差较大点，丢弃");
        _journeyRecord.valid = NO;
    } else if (fabs(interval) > 10) {
        NSLog(@"新记录为卫星缓存点，丢弃");
        _journeyRecord.valid = NO;
    }
    
    //去噪算法
    if (_currentPedometerType ==  PedometerType_Stop) {
        //静止的时候判断一个点偏移的距离不靠谱就返回
        if (_journeyRecord.recordId>0 && meters > (timeStamp - _journeyRecord.recordId) * WALKING_SPEED * 1.5) {
            NSLog(@"新记录因去噪算法判定为禁止下的噪点，丢弃");
            _journeyRecord.valid = NO;
        }
    } else if (_currentPedometerType ==  PedometerType_Walk) {
        //走路的时候判断一个点偏移的距离不靠谱就返回
        if (_journeyRecord.recordId > 0 && meters > (timeStamp - _journeyRecord.recordId) * WALKING_SPEED * 1.5) {
            NSLog(@"新记录因去噪算法判定为走路下的噪点，丢弃");
            _journeyRecord.valid = NO;
        }
    } else if (_currentPedometerType ==  PedometerType_Drive){
        if (_journeyRecord.recordId > 0 && meters > (timeStamp - _journeyRecord.recordId) * MAPPOINT_HIGHTSPEED * 1.5) {
            NSLog(@"新记录因去噪算法判定为开车下的噪点，丢弃");
            _journeyRecord.valid = NO;
        }
    }
    
    //单位时间前进方向角要小于45度
    if (_currentPedometerType ==  PedometerType_Drive) {
        if (course >=0 && _journeyRecord.orientation >=0) {
            float jiajiao = fabs(_journeyRecord.orientation - course);
            if (jiajiao > 180) {
                jiajiao = 360 - jiajiao;
            }
            if (fabs(jiajiao/((long)timeStamp - _journeyRecord.recordId)) > 45) {
                NSLog(@"新记录方向角改变异常,丢弃");
                _journeyRecord.valid = NO;
            }
        }
    }
    _journeyRecord.orientation = course;
    
    //设置经纬度等
    _journeyRecord.altitude = newLocation.altitude;
    _journeyRecord.longitude = longitude;
    _journeyRecord.latitude = latitude;
    _journeyRecord.speed = speed;
    _journeyRecord.connectedState = [_globals currentConnectedState];
    
    //判断是步行后稳定算法
    if (_currentPedometerType ==  PedometerType_Walk){
        _journeyRecord.recordType = RecordType_Walk;
    } else if (_currentPedometerType ==  PedometerType_Drive){
        _journeyRecord.recordType = RecordType_Drive;
    } else if (_currentPedometerType ==  PedometerType_Stop){
        _journeyRecord.recordType = RecordType_Stop;
    }
    
    //电话状态
    _journeyRecord.callState = _currentCallState;
    
    //检测异常类型并播报
    if (_currentPedometerType ==  PedometerType_Drive && _journeyRecord.valid){
        if(_callState == CallState_CallOut||_callState == CallState_CallOutDone){
            //非蓝牙打电话才是危险驾驶行为
            if (![_globals isBluetoothDevice] && speed > STOP_SPEED) {
                if (_callState == CallState_CallOut||_callState == CallState_CallOutDone){
                    //打电话
                    _journeyRecord.recordType = RecordType_CallPhone;
                }
            }
            _callState = CallState_Unknow;
        } else if(_currentCallState == CallState_Disconnected){
            //非蓝牙接电话才是危险驾驶行为
            if (![_globals isBluetoothDevice] && speed > STOP_SPEED) {
                if (_callState == CallState_CallInDone) {
                    //接听电话
                    _journeyRecord.recordType = RecordType_AnswerPhone;
                }
            }
            _callState = CallState_Unknow;
        } else if ([_recordArray count] >= 3) {
            //当前记录点和前面的第2个记录点比较判断异常
            DSJourneyRecordModel *fristTravelRecord = [_recordArray objectAtIndex:[_recordArray count]-3];
            DSJourneyRecordModel *secondTravelRecord = [_recordArray objectAtIndex:[_recordArray count]-2];
            DSJourneyRecordModel *thirdTravelRecord = [_recordArray objectAtIndex:[_recordArray count]-1];
            if (fristTravelRecord.valid && secondTravelRecord.valid && thirdTravelRecord.valid && _journeyRecord.valid && fristTravelRecord.recordType == RecordType_Drive && secondTravelRecord.recordType == RecordType_Drive && thirdTravelRecord.recordType == RecordType_Drive) {
                //核心算法要求前面三个点都有效
                float jiajiao = fabs(_journeyRecord.orientation - fristTravelRecord.orientation);
                float timespan = timeStamp - (double)fristTravelRecord.timeStamp/1000;
                float speed = (fristTravelRecord.speed+secondTravelRecord.speed+thirdTravelRecord.speed+_journeyRecord.speed)/4;
                if (timespan < 6) {
                    //参照的时间间隔不能大于10秒
                    if (jiajiao > 180) {
                        jiajiao = 360 - jiajiao;
                    }
                    if (jiajiao < 30) {
                        //急加速，急减速 先计算区间内有效加速度和平均速度
                        float acceleretions = (_journeyRecord.speed-fristTravelRecord.speed)/(timeStamp-(double)fristTravelRecord.timeStamp/1000)*0.3
                        +(_journeyRecord.speed-secondTravelRecord.speed)/(timeStamp-(double)secondTravelRecord.timeStamp/1000)*0.3+(_journeyRecord.speed-thirdTravelRecord.speed)/(timeStamp-(double)thirdTravelRecord.timeStamp/1000)*0.4;
                        float currentAcc = (_journeyRecord.speed-thirdTravelRecord.speed)/(timeStamp-(double)thirdTravelRecord.timeStamp/1000);
                        if (currentAcc >= 6||currentAcc <= -8) {
                            //异常加速度,速度用上一点和当前点换算
                            NSLog(@"新记录因加速度异常，丢弃");
                            _journeyRecord.valid = NO;
                        } else {
                            //判断异常加速度
                            for (NSNumber *speedUp in _globals.orderedSpeedUpArray) {
                                if (speed >= speedUp.floatValue) {
                                    NSNumber *speedUpNum = [_globals.speedUpDict objectForKey:speedUp];
                                    NSNumber *slowDownNum = [_globals.slowDownDict objectForKey:speedUp];
                                    if (acceleretions > speedUpNum.floatValue) {
                                        //急加速
                                        if (fristTravelRecord.speed>0 && secondTravelRecord.speed>0 && thirdTravelRecord.speed>0 && _journeyRecord.speed > 0) {
                                            if (fristTravelRecord.speed <= secondTravelRecord.speed && secondTravelRecord.speed <= thirdTravelRecord.speed && thirdTravelRecord.speed <= _journeyRecord.speed) {
                                                _journeyRecord.recordType = RecordType_HeavyStart;
                                            }
                                        }
                                    } else if (acceleretions < slowDownNum.floatValue){
                                        if (fristTravelRecord.speed>0 && secondTravelRecord.speed>0 && ((thirdTravelRecord.speed>0 && _journeyRecord.speed>0)||(thirdTravelRecord.speed==0 &&_journeyRecord.speed==0))) {
                                            if (fristTravelRecord.speed >= secondTravelRecord.speed && secondTravelRecord.speed >= thirdTravelRecord.speed && thirdTravelRecord.speed >= _journeyRecord.speed) {
                                                _journeyRecord.recordType = RecordType_HeavyBrake;
                                            }
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    } else if (speed > _globals.turnSpeed && jiajiao>_globals.turnAngle && fristTravelRecord.orientation >=0 && _journeyRecord.orientation >=0) {
                        //急转弯
                        if (_journeyRecord.orientation <= 180) {
                            if (fristTravelRecord.orientation>_journeyRecord.orientation && fristTravelRecord.orientation<_journeyRecord.orientation+180) {
                                _journeyRecord.recordType = RecordType_HeavyTurnLeft;
                            } else {
                                _journeyRecord.recordType = RecordType_HeavyTurnRight;
                            }
                        } else {
                            if (fristTravelRecord.orientation<_journeyRecord.orientation &&fristTravelRecord.orientation>_journeyRecord.orientation-180) {
                                _journeyRecord.recordType = RecordType_HeavyTurnRight;
                            } else {
                                _journeyRecord.recordType = RecordType_HeavyTurnLeft;
                            }
                        }
                    }
                }
            }
        }
        //异常处理
        if (_journeyRecord.recordType >= RecordType_HeavyBrake) {
            int timeValue = 0;
            if (_journeyRecord.recordType == _previouAbnormalType) {
                //相同的异常有不同的间隔时间
                if (_journeyRecord.recordType == RecordType_HeavyBrake||_journeyRecord.recordType == RecordType_HeavyStart) {
                    timeValue = 10;
                } else if(_journeyRecord.recordType == RecordType_HeavyTurnLeft||_journeyRecord.recordType == RecordType_HeavyTurnRight){
                    timeValue = 10;
                } else if (_journeyRecord.recordType == RecordType_CrazySpeed){
                    timeValue = 20;
                } else {
                    timeValue = 30;
                }
            } else {
                timeValue = 0;
            }
            _currentInterval = [[NSDate date]timeIntervalSince1970];
            if ((_currentInterval - _previousInterval) >= timeValue) {
                //满足异常的间隔时间
                _previouAbnormalType = _journeyRecord.recordType;
                _previousInterval = _currentInterval;
                //播放声音
                if (_previouAbnormalType == RecordType_HeavyBrake) {
                    NSLog(@"新记录是异常点 异常类型为：急刹车");
                } else if (_previouAbnormalType == RecordType_HeavyStart){
                    NSLog(@"新记录是异常点 异常类型为：急启动");
                } else if (_previouAbnormalType == RecordType_HeavyTurnLeft){
                    NSLog(@"新记录是异常点 异常类型为：急左转");
                } else if (_previouAbnormalType == RecordType_HeavyTurnRight){
                    NSLog(@"新记录是异常点 异常类型为：急右转");
                } else if (_previouAbnormalType == RecordType_CrazySpeed){
                    NSLog(@"新记录是异常点 异常类型为：超限速");
                } else if (_previouAbnormalType == RecordType_CallPhone){
                    NSLog(@"新记录是异常点 异常类型为：打电话");
                } else if (_previouAbnormalType == RecordType_AnswerPhone){
                    NSLog(@"新记录是异常点 异常类型为：接电话");
                } else if (_previouAbnormalType == RecordType_SendMessage){
                    NSLog(@"新记录是异常点 异常类型为：发短信");
                } else if (_previouAbnormalType == RecordType_ReadMessage){
                    NSLog(@"新记录是异常点 异常类型为：读短信");
                } else if (_previouAbnormalType == RecordType_UsePhone){
                    NSLog(@"新记录是异常点 异常类型为：玩手机");
                }
            } else {
                //不满足异常的时间，回置类型
                _journeyRecord.recordType = RecordType_Drive;
            }
        }
    } else if(_currentPedometerType ==  PedometerType_Walk){
        //重置电话状态
        _callState = CallState_Unknow;
    } else if(_currentPedometerType ==  PedometerType_Stop){
        //重置电话状态
        _callState = CallState_Unknow;
    }
    
    //添加新的行程
    if (_journeyRecord.journeyId != journeyId || _journeyRecord.userId != userId) {
        DSJourneyModel *journeyModel = [[DSJourneyModel alloc] init];
        journeyModel.journeyId = journeyId;
        journeyModel.userId = userId;
        journeyModel.distance = -1;
        journeyModel.timeSpend = -1;
        journeyModel.averageSpeed = -1;
        journeyModel.maxSpeed = -1;
        [_journeyArray addObject:journeyModel];
    }
    
    //设置核心字段
    _journeyRecord.journeyId = journeyId;
    _journeyRecord.userId = userId;
    _journeyRecord.roadwayId = 0;
    _journeyRecord.recordId = timeStamp;
    _journeyRecord.timeStamp = timeStamp * 1000;
    
    if (_journeyRecord.recordType == RecordType_Drive) {
        _stopTimeInterval = timeStamp;
    }
    
    //保存到缓存
    [_recordArray addObject:[_journeyRecord mutableCopy]];
    
    //去除异常急转弯方法
    if(_recordArray.count >= 20){
        DSJourneyRecordModel *checkJourneyRecord = [_recordArray objectAtIndex:_recordArray.count - 11];
        if (checkJourneyRecord.recordType == RecordType_HeavyTurnLeft || checkJourneyRecord.recordType == RecordType_HeavyTurnRight) {
            if (![self checkPointVaildByCurrentTravelRecord:checkJourneyRecord]) {
                //检测不合格，回滚类型
                checkJourneyRecord.recordType = RecordType_Drive;
            }
        }
    }
    
    //保存缓存
    [self saveTravelRecordAndLogInfoWithSaveRecordTimerType:SaveRecordTimerType_Location];

    
}

-(void)startLocationServerWithDesiredAccuracy:(CLLocationAccuracy)_desiredAccuracy{
    if (!_globals.canAutoStartLocationServerOnBack) {
        return;
    }
    CLLocationAccuracy desiredAccuracy = _desiredAccuracy;
    if (_isLocationServerStarted && desiredAccuracy == _locationManager.desiredAccuracy) {
        //精度没有任何改变不做任何事
        return;
    }
    if (_isLocationServerStarted && _desiredAccuracy == kCLLocationAccuracyBest) {
        //低电量时无法切换到高精度定位
        float batteryLevel = [DSRecordConfig getBatteryLevel];
        if ((batteryLevel < DSLOWPOWER && batteryLevel >= 0) && [[UIDevice currentDevice] batteryState] != UIDeviceBatteryStateCharging) {
            return;
        }
    }
    if (!_isLocationServerStarted) {
        NSLog(@"开启定位服务,定位精确度 从%f 调到%f", _locationManager.desiredAccuracy,desiredAccuracy);
    } else {
        NSLog(@"重新调整手机定位精确度 从%f 调到%f",_locationManager.desiredAccuracy,desiredAccuracy);
    }
    //先停止可能的定位服务
    if (_isLocationServerStarted) {
        [self stopLocationServer];
    }
    //重新计算停止标签
    _stopTimeInterval = [[NSDate date] timeIntervalSince1970];
    //开启定位
    _locationManager.desiredAccuracy = desiredAccuracy;
    _locationManager.delegate = self;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 6.0) {
        _locationManager.pausesLocationUpdatesAutomatically = NO;
    }
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locationManager requestAlwaysAuthorization];
    }
    [_locationManager startUpdatingLocation];
    _isLocationServerStarted = YES;
}

-(void)stopLocationServer{
    _locationManager.delegate = nil;
    //关闭定位
    [_locationManager stopUpdatingLocation];
    //设置定位标志
    _isLocationServerStarted = NO;
}

#pragma mark - CMService Action 

-(void)stopAccelerometerServer{
    //关闭陀螺仪服务
    [_motionManager stopAccelerometerUpdates];
    _pedometer = 0;
}

-(void)startAccelerometerServer:(AccelerometerType)_ccelerometerType{
    //开启感应器,感应器有两种状态1.记步状态 2.定时判断会写状态
    if (_motionManager.isAccelerometerActive && _accelerometerType == _ccelerometerType) {
        return;
    } else {
        //关闭陀螺仪服务
        if ([_motionManager isAccelerometerActive]) {
            if (_accelerometerType == AccelerometerType_Custom) {
                NSLog(@"切换加速计模式，从正常模式切换到定时回写模式");
            } else {
                NSLog(@"切换加速计模式，从定时回写模式切换到正常模式");
            }
            //关闭加速计
            [_motionManager stopAccelerometerUpdates];
        } else {
            if (_ccelerometerType == AccelerometerType_Custom) {
                NSLog(@"开启加速计，设定为正常模式");
            } else {
                NSLog(@"开启加速计，设定为定时回写模式");
            }
        }
        
        //切换状态
        if (_ccelerometerType == AccelerometerType_Custom) {
            //记步状态
            __block float lastTimeTag = 0.0;
            _motionManager.accelerometerUpdateInterval  = 1/100;
            if (_motionManager.accelerometerAvailable) {
                [_motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *data,NSError *error){
                    //25个pull值只取一个
                    if (data.timestamp - lastTimeTag < 0.25) {
                        //丢弃多余的点
                        return ;
                    } else {
                        lastTimeTag = data.timestamp;
                    }
                    
                    _acc = data.acceleration;
                    
                    float xx = data.acceleration.x;
                    float yy = data.acceleration.y;
                    float zz = data.acceleration.z;
                    
                    float dot = (_px * xx) + (_py * yy) + (_pz * zz);
                    float a = ABS(sqrt(_px * _px + _py * _py + _pz * _pz));
                    float b = ABS(sqrt(xx * xx + yy * yy + zz * zz));
                    dot /= (a * b);
                    
                    if (dot <= 0.82) {
                        //成功感测到一步，动走步的可能性增加
                        if (_pedometer < PEDOMETERTYPEWALK_VALUE * 10) {
                            _pedometer += PEDOMETERTYPEWALK_VALUE;
                        }
                    } else {
                        //检测到非走步，移动走步的可能行减一
                        if (_pedometer > 0) {
                            _pedometer--;
                        }
                    }
                    _px = xx; _py = yy; _pz = zz;
                }
                 ];
            }
        } else {
            //加速计定时写回方案
            _motionManager.accelerometerUpdateInterval  = 60*10;
            if (_motionManager.accelerometerAvailable) {
                [_motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *data,NSError *error){
                    [self saveTravelRecordAndLogInfoWithSaveRecordTimerType:SaveRecordTimerType_Acceleration];
                }];
            }
        }
        _accelerometerType = _ccelerometerType;
    }
}

-(void)startCMStepServer{
    if (_isCMServerActivity) {
        return;
    }
    //手机状态
    if ([CMMotionActivityManager isActivityAvailable]) {
        if (!_activityManager) {
            _activityManager = [[CMMotionActivityManager alloc] init];
        }
        _isCMServerActivity = YES;
        NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
        [_activityManager startActivityUpdatesToQueue:operationQueue
                                         withHandler: ^(CMMotionActivity *activity) {
                                             //判断当前的运动状态
                                             if (activity.automotive) {
                                                 if (_currentPedometerType != PedometerType_Drive) {
                                                     NSLog(@"M7开始判断为开车，提高到最佳精度");
                                                 }
                                                 //提高到最佳精度
                                                 [self startLocationServerWithDesiredAccuracy:kCLLocationAccuracyBest];
                                                 _currentPedometerType = PedometerType_Drive;
                                             } else if(activity.walking || activity.running){
                                                 if (_currentPedometerType != PedometerType_Walk) {
                                                     NSLog(@"M7开始判断为走路");
                                                 }
                                                 _currentPedometerType = PedometerType_Walk;
                                             } else if (activity.stationary){
                                                 if (_currentPedometerType != PedometerType_Stop) {
                                                     NSLog(@"M7开始判断为静止");
                                                 }
                                                 _currentPedometerType = PedometerType_Stop;
                                             }
                                             _confidence = activity.confidence;
                                             //M7方案下的定时写回机制
                                             [self saveTravelRecordAndLogInfoWithSaveRecordTimerType:SaveRecordTimerType_M7];
                                         }];
    }
}

-(void)stopCMStepServer{
    NSLog(@"关闭CM服务");
    [_activityManager stopActivityUpdates];
    _isCMServerActivity = NO;
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

#pragma mark - Private

//检测急转弯点是否合理
-(BOOL)checkPointVaildByCurrentTravelRecord:(DSJourneyRecordModel *)checkJourneyRecord {
    DSJourneyRecordModel *lastJourneyRecord = [_recordArray objectAtIndex:_recordArray.count - 12];
    DSJourneyRecordModel *nextJourneyRecord = [_recordArray objectAtIndex:_recordArray.count - 10];
    float avspeed = (checkJourneyRecord.speed + lastJourneyRecord.speed + nextJourneyRecord.speed)/3;
    //统计落在圈内的点数
    int count = 0;
    for (NSInteger index = _recordArray.count-20 ;index < _recordArray.count;index++) {
        DSJourneyRecordModel *currentJourneyRecord = (DSJourneyRecordModel *)[_recordArray objectAtIndex:index];
        float meters = [[[CLLocation alloc] initWithLatitude:checkJourneyRecord.latitude longitude:checkJourneyRecord.longitude] distanceFromLocation:[[CLLocation alloc] initWithLatitude:currentJourneyRecord.latitude longitude:currentJourneyRecord.longitude]];
        if (meters <= avspeed*2) {
            count ++;
        }
    }
    if (count <= 8) {
        return TRUE;
    } else {
        return FALSE;
    }
}

#pragma mark - Caches

- (void)saveTravelRecordAndLogInfoWithSaveRecordTimerType:(SaveRecordTimerType)saveRecordTimerType {
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        return;
    }
    //保存定位信息和日志信息
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

- (void)saveAllRecordInfo{
    //保存行程数据
    if (_journeyArray.count + _recordArray.count + _eventArray.count> 0) {
        NSLog(@"保存阶段,开始保存");
        [_databaseService.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL needrollback = NO;
            for (int index=0;!needrollback && index < _journeyArray.count; index++) {
                DSJourneyModel *currentJourneyInfo = [_journeyArray objectAtIndex:index];
                needrollback = needrollback || [_databaseService saveDSJourneyModel:currentJourneyInfo fmdb:db];
            }
            for (int index = 0;!needrollback && index < [_recordArray count]; index++) {
                DSJourneyRecordModel *currentJourneyRecord = [_recordArray objectAtIndex:index];
                needrollback = needrollback || [_databaseService saveDSJourneyRecordModel:currentJourneyRecord fmdb:db];
            }
            for (int index = 0;!needrollback && index < [_eventArray count]; index++) {
                DSEventInfoModel *currentEventInfo = [_eventArray objectAtIndex:index];
                needrollback = needrollback || [_databaseService saveEventInfoModel:currentEventInfo fmdb:db];
            }
            if (needrollback) {
                *rollback = YES;
                NSLog(@"保存阶段，保存行程失败，回滚");
            } else {
                if ([db commit]) {
                    NSLog(@"保存阶段，保存行程成功，删除行程缓存");
                    //删除缓存
                    [_journeyArray removeAllObjects];
                    [_recordArray removeAllObjects];
                    [_eventArray removeAllObjects];
                    //发送保存完成的全局通知
                    [self performSelectorOnMainThread:@selector(didSaveAllData) withObject:nil waitUntilDone:NO];
                } else {
                    *rollback = YES;
                    NSLog(@"保存阶段，保存行程失败，回滚");
                }
            }
        }];
    } else {
        //发送保存完成的全局通知
        [self performSelectorOnMainThread:@selector(didSaveAllData) withObject:nil waitUntilDone:NO];
    }
    
    //保存日志信息 后面补充日志系统
//    if (logDetailInfoArray.count> 0) {
//        [logServer.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
//            BOOL needrollback = NO;
//            for (int index = 0;!needrollback && index<[logDetailInfoArray count]; index++) {
//                logDetailModel *logDetailModel = [logDetailInfoArray objectAtIndex:index];
//                needrollback = needrollback || [logServer saveLogDetailInfoModel:logDetailModel fmdb:db];
//            }
//            if (needrollback) {
//                *rollback = YES;
//                [self addLogInfoWithLogType:type_bebug logText:@"保存阶段，保存日志失败，回滚"];
//            } else {
//                if ([db commit]) {
//                    [self addLogInfoWithLogType:type_bebug logText:@"保存阶段，保存日志成功，删除日志缓存"];
//                    //删除缓存
//                    [logDetailInfoArray removeAllObjects];
//                    //发送保存完成的全局通知
//                    [[NSNotificationCenter defaultCenter] postNotificationName:PINGAN_LOCAL_ALLLOGINFODIDSAVAED object:nil];
//                } else {
//                    *rollback = YES;
//                    [self addLogInfoWithLogType:type_bebug logText:@"保存阶段，保存日志失败，回滚"];
//                }
//            }
//        }];
//    }
}

-(void)didSaveAllData {
    [[NSNotificationCenter defaultCenter] postNotificationName:DSNotificationNameAllJouneryDidSaved object:nil];
}


@end
