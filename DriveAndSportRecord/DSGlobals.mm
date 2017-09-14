//
//  DSGlobals.m
//  DriveAndSportRecord
//
//  Created by Tristan on 2017/9/1.
//  Copyright © 2017年 Tristan. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "DSGlobals.h"
#import "OpenUDID.h"
#import "DSRecordConfig.h"
#import "DSDriveAndSportRecord.h"


NSString *kAudioSessionManagerDevice_Headset    = @"AudioSessionManagerDevice_Headset";
NSString *kAudioSessionManagerDevice_Bluetooth  = @"AudioSessionManagerDevice_Bluetooth";
NSString *kAudioSessionManagerDevice_Phone      = @"AudioSessionManagerDevice_Phone";
NSString *kAudioSessionManagerDevice_Speaker    = @"AudioSessionManagerDevice_Speaker";
NSString *kAudioSessionManagerDevice_Unknow     = @"AudioSessionManagerDevice_Unknow";

@interface DSGlobals ()

@property (nonatomic, assign) NSInteger userId;

@end

@implementation DSGlobals

+ (instancetype)sharedGlobals {
    static DSGlobals *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init{
    //init改方法中不能调用logserver否则会死循环
    self = [super init];
    if (self) {
        
        _isRefreshed = NO;
        _isBingding  = NO;
        _autoUpload  = YES;
        _isDebug     = NO;
        
        //读取缓存文件
        [self getConfigInfo];
        
        //刷新阀值失败
        if (!_isRefreshed) {
            //设置默认值
            _driveInterval   = 2;
            _walkInterval    = 4;
            _turnSpeed       = 35/3.6;
            _turnAngle       = 45;
            _maxPackage      = 500;
            _maxThreadNum    = 3;
            _tireDrive       = 10800;
            //异常判断阀值
            self.speedUpDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.35],[NSNumber numberWithFloat:12.5],[NSNumber numberWithFloat:1.95],[NSNumber numberWithFloat:6.95],[NSNumber numberWithFloat:2.35],[NSNumber numberWithFloat:0], nil];
            self.slowDownDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:-2.35],[NSNumber numberWithFloat:12.5],[NSNumber numberWithFloat:-2.75],[NSNumber numberWithFloat:6.95],[NSNumber numberWithFloat:-2.95],[NSNumber numberWithFloat:0], nil];
            [self getOrderedSpeedUpArray];
        }
        
        //设置默认值
        self.osType         = @"iPhone";
        self.version        = [DSRecordConfig appVersion];
        
    }
    return self;
}

//获得有序的数据分档
- (void)getOrderedSpeedUpArray{
    //结合加权加速度和平均时速判断急加速急减速
    NSArray *speedUpArray = [self.speedUpDict allKeys];
    self.orderedSpeedUpArray = [speedUpArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber *number1 = (NSNumber *)obj1;
        NSNumber *number2 = (NSNumber *)obj2;
        NSComparisonResult result = [number1 compare:number2];
        if (result == NSOrderedAscending) {
            return NSOrderedDescending;
        } else if (result == NSOrderedDescending){
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
}

- (DSDatabaseService *)databaseService {
    if (!databaseService) {
        databaseService = [[DSDatabaseService alloc] init];
    }
    if (!databaseService.state) {
        [databaseService open];
    }
    return databaseService;
}

- (DSBackgroungTask *)backgroundTask {
    if (!backgroundTask) {
        backgroundTask = [[DSBackgroungTask alloc] initWithUserid:_userId];
    }
    return backgroundTask;
}


- (DSDataAnalyze *)dataAnalyze {
    if (!dataAnalyze) {
        dataAnalyze = [[DSDataAnalyze alloc] init];
    }
    return dataAnalyze;
}


- (void)didBecomeActive {
    
    [[self backgroundTask] saveTravelRecordAndLogInfoWithSaveRecordTimerType:SaveRecordTimerType_Force];
    dispatch_async(dispatch_get_main_queue(), ^{
        //检测是否开启GPS
        NSLog(@"进前台 开始检测是否开启定位");
        [self checkLocationServer];
    });
}

//检测是否开启定位
- (void)checkLocationServer {
    //已经提示过了用户打开运动侦测
    BOOL pingServer = [[NSUserDefaults standardUserDefaults] boolForKey:DS_SERVER_FIRST_BOOL_KEY];
    if (pingServer) {
        double nowInterval = [[NSDate date] timeIntervalSince1970];
        double beforeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:DS_SERVER_UPDATE_DATE];
        double timeInterval = nowInterval - beforeInterval;
        double secendInterval = 60*60*3;
        if (beforeInterval == 0 || timeInterval >= secendInterval) {
            NSTimeInterval updateServerInterval = [[NSDate date] timeIntervalSince1970];
            [[NSUserDefaults standardUserDefaults] setDouble:updateServerInterval forKey:DS_SERVER_UPDATE_DATE];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            return;
        }
    }
    
    //
    BOOL isOpenDSServer = self.canAutoStartLocationServerOnBack;
    BOOL isOpenGPS = [DSDriveAndSportRecord sharedRecord].isLocationServicesEnabled && [DSDriveAndSportRecord sharedRecord].isAuthorized;
    BOOL needAlertDS = NO;
    BOOL needAlertGPS = NO;
    if (isOpenDSServer) {
        if (isOpenGPS) {
            needAlertGPS = NO;
            needAlertDS = NO;
        }else{
            //toast
            needAlertGPS = YES;
            needAlertDS = YES;
        }
    }else{
        //没开平安行
        needAlertDS = YES;
        needAlertGPS = NO;
    }
    if (needAlertDS) {
        NSLog(@"检测用户没有开启运动状态侦测服务，提示用户开启");
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"开启服务" message:@"运动状态服务未启用，是否启用"
                                                          delegate:self
                                                 cancelButtonTitle:@"否"
                                                 otherButtonTitles:@"是", nil];
        alertView.tag = 1000001;
        [alertView show];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DS_SERVER_FIRST_BOOL_KEY];
        NSTimeInterval updateServerInterval = [[NSDate date] timeIntervalSince1970];
        [[NSUserDefaults standardUserDefaults] setDouble:updateServerInterval forKey:DS_SERVER_UPDATE_DATE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if (needAlertGPS) {
        NSLog(@"请在“设置-隐私-定位服务”打开定位服务");//需要提示
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DS_SERVER_FIRST_BOOL_KEY];
        NSTimeInterval updateServerInterval = [[NSDate date] timeIntervalSince1970];
        [[NSUserDefaults standardUserDefaults] setDouble:updateServerInterval forKey:DS_SERVER_UPDATE_DATE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


//保存配置信息0-999
- (void)saveConfigInfo{
    //获取配置文件
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *allConfigInfoPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"allConfigInfo.plist"];
    NSMutableDictionary *allConfigInfoDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:allConfigInfoPath];
    if (allConfigInfoDictionary == nil) {
        allConfigInfoDictionary = [NSMutableDictionary dictionary];
    }
    //写配置信息
    [allConfigInfoDictionary setObject:[NSNumber numberWithInteger:_driveInterval] forKey:@"drive"];
    [allConfigInfoDictionary setObject:[NSNumber numberWithInteger:_walkInterval] forKey:@"walk"];
    [allConfigInfoDictionary setObject:[NSNumber numberWithFloat:_turnSpeed] forKey:@"turnSpeed"];
    [allConfigInfoDictionary setObject:[NSNumber numberWithFloat:_turnAngle] forKey:@"turnAngle"];
    [allConfigInfoDictionary setObject:_speedUpDict forKey:@"speedUp"];
    [allConfigInfoDictionary setObject:_slowDownDict forKey:@"slowDown"];
    [allConfigInfoDictionary setObject:[NSNumber numberWithInteger:_tireDrive] forKey:@"tireDrive"];
    [allConfigInfoDictionary setObject:[NSNumber numberWithInteger:_maxPackage] forKey:@"package"];
    [allConfigInfoDictionary setObject:[NSNumber numberWithInteger:_maxThreadNum] forKey:@"threadNum"];
    if (_refreshDate) {
        [allConfigInfoDictionary setObject:_refreshDate forKey:@"refreshDate"];
    }
    [allConfigInfoDictionary setObject:[NSNumber numberWithBool:_isDebug] forKey:@"isDebug"];
    //写回文件
    [allConfigInfoDictionary writeToFile:allConfigInfoPath atomically:TRUE];
}

//获取本地的配置信息（一天以内只请求一次，其余的时候从配置文件读取）
- (void)getConfigInfo{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *allConfigInfoPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"allConfigInfo.plist"];
    NSMutableDictionary *allConfigInfoDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:allConfigInfoPath];
    if (allConfigInfoDictionary != nil) {
        //读取配置文件
        self.refreshDate = [allConfigInfoDictionary objectForKey:@"refreshDate"];
        NSDate *vaildDate = [NSDate dateWithTimeInterval:24*60*60 sinceDate:self.refreshDate];
        if (_refreshDate && [vaildDate timeIntervalSinceDate:[NSDate date]] > 0) {
            NSDictionary *speedUpDictonary = [allConfigInfoDictionary objectForKey:@"speedUp"];
            NSDictionary *slowDownDictonary = [allConfigInfoDictionary objectForKey:@"slowDown"];
            if ([speedUpDictonary isKindOfClass:[NSDictionary class]] && [slowDownDictonary isKindOfClass:[NSDictionary class]] ) {
                self.driveInterval = [[allConfigInfoDictionary objectForKey:@"drive"] integerValue];
                self.walkInterval = [[allConfigInfoDictionary objectForKey:@"walk"] integerValue];
                self.turnSpeed = [[allConfigInfoDictionary objectForKey:@"turnSpeed"] floatValue];
                self.turnAngle = [[allConfigInfoDictionary objectForKey:@"turnAngle"] floatValue];
                self.speedUpDict = speedUpDictonary;
                self.slowDownDict = slowDownDictonary;
                self.maxPackage = [[allConfigInfoDictionary objectForKey:@"package"] integerValue];
                self.maxThreadNum = [[allConfigInfoDictionary objectForKey:@"threadNum"] integerValue];
                self.isDebug =  [[allConfigInfoDictionary objectForKey:@"isDebug"] boolValue];
                if ([allConfigInfoDictionary objectForKey:@"tireDrive"]) {
                    self.tireDrive = [[allConfigInfoDictionary objectForKey:@"tireDrive"] intValue];
                } else {
                    self.tireDrive = 10800;
                }
                [self getOrderedSpeedUpArray];
                self.isRefreshed = TRUE;
                return;
            }
        }
    }
    self.isRefreshed = FALSE;
}

- (void)showRoadToast {

}
- (void)getAllSetinfo {

}


/*!
 @method convertWgs84ToGcj02:andlatitude
 @abstract 传递苹果坐标系定位得到的原始经纬度坐标值，经过本地纠偏函数纠偏后得到Gcj02标准的经纬度坐标
 @discussion 输出参数为Apple 经纬度结构体数据类型CLLocationCoordinate2D
 @result CLLocationCoordinate2D
 */
+ (CLLocationCoordinate2D) convertWgs84ToGcj02:(double)originlongitude andlatitude:(double)originlatitude
{
    float convertlongitude = 0.0f;
    float convertlatitude = 0.0f;
    togcj_table(originlongitude, originlatitude, &convertlongitude, &convertlatitude);
    CLLocationCoordinate2D convertLocation = {convertlatitude,convertlongitude};
    return convertLocation;
}

+ (NSInteger)getTravelIdByTimeInterval:(NSTimeInterval)timetag {
    NSString *dateStr = [DSRecordConfig stringFromDate:[NSDate dateWithTimeIntervalSince1970:timetag] format:@"yyyyMMdd"];
    return dateStr.integerValue;
}


+ (NSString *)getTravelIdByDate:(NSDate *)date {
    NSString *dateStr = [DSRecordConfig stringFromDate:date format:@"yyyyMMdd"];
    return dateStr;
}


+ (NSInteger)getRoadwayIdByTimeInterval:(NSTimeInterval)timetag currentIndex:(NSInteger)index{
    NSString *dateStr = [NSString stringWithFormat:@"%@%ld", [DSRecordConfig stringFromDate:[NSDate dateWithTimeIntervalSince1970:timetag] format:@"yyyyMMdd"], (long)index];
    return dateStr.integerValue;
}

+ (NSString *)getTimeIntervalToStr:(NSTimeInterval)timetag{
    NSString *dateStr = [DSRecordConfig stringFromDate:[NSDate dateWithTimeIntervalSince1970:timetag] format:@"yyyy-MM-dd HH:mm:ss"];
    return dateStr;
}

+ (NSString *)getTimeIntervalToStr1:(NSTimeInterval)timetag{
    NSString *dateStr = [DSRecordConfig stringFromDate:[NSDate dateWithTimeIntervalSince1970:timetag] format:@"yyMMddHHmmss"];
    return dateStr;
}

+ (NSString *)getTimeIntervalToStr2:(NSTimeInterval)timetag{
    NSString *dateStr = [DSRecordConfig stringFromDate:[NSDate dateWithTimeIntervalSince1970:timetag] format:@"yyMMddHHmm"];
    return dateStr;
}

+ (NSString *)getTimeIntervalToString:(NSTimeInterval)timetag{
    NSString *dateStr = [DSRecordConfig stringFromDate:[NSDate dateWithTimeIntervalSince1970:timetag] format:@"HH:mm:ss"];
    return dateStr;
}

+ (NSString *)getTimeIntervalToHM:(NSTimeInterval)timetag{
    NSString *dateStr = [DSRecordConfig stringFromDate:[NSDate dateWithTimeIntervalSince1970:timetag] format:@"HH:mm"];
    return dateStr;
}


+ (NSString *)getTimeIntervalToDate:(NSTimeInterval)timetag{
    NSString *dateStr = [DSRecordConfig stringFromDate:[NSDate dateWithTimeIntervalSince1970:timetag] format:@"yyyy-MM-dd"];
    return dateStr;
}

+ (OrientationType)getOrientationTypeByCourse:(NSInteger)course{
    if ((course >= 0 && course < 45)||
        course >  315) {
        return OrientationType_North;
    } else if(course >= 45 && course < 135){
        return OrientationType_East;
    } else if(course >= 135 && course < 225){
        return OrientationType_South;
    } else {
        return OrientationType_West;
    }
}


- (NSString *)getMapPointTypeDescribe:(MapPointType)mapPointType{
    NSString *describe = nil;
    switch (mapPointType) {
        case MapPointType_UnKnow:
            describe = @"未知点";
            break;
        case MapPointType_BeginPoint:
            describe = @"起点";
            break;
        case MapPointType_EndPoint:
            describe = @"终点";
            break;
        case MapPointType_StopPoint:
            describe = @"停止点";
            break;
        case MapPointType_RoadWayPoint:
            describe = @"分段点";
            break;
        case MapPointType_WalkPoint:
            describe = @"走路点";
            break;
        case MapPointType_DriverPoint:
            describe = @"开车点";
            break;
        case MapPointType_HeavyBrake:
            describe = @"急刹车";
            break;
        case MapPointType_HeavyStart:
            describe = @"急加速";
            break;
        case MapPointType_HeavyTurnLeft:
            describe = @"急左转";
            break;
        case MapPointType_HeavyTurnRight:
            describe = @"急右转";
            break;
        case MapPointType_CrazySpeed:
            describe = @"超速";
            break;
        case MapPointType_CallPhone:
            describe = @"打电话";
            break;
        case MapPointType_AnswerPhone:
            describe = @"接电话";
            break;
        case MapPointType_SendMessage:
            describe = @"发短信";
            break;
        case MapPointType_ReadMessage:
            describe = @"读短信";
            break;
        case MapPointType_UsePhone:
            describe = @"玩手机";
            break;
        case MapPointType_FatigueDriving:
            describe = @"疲劳驾驶";
            break;
        case MapPointType_SpeedNotMatch:
            describe = @"转速不匹配";
            break;
        case MapPointType_HighRotationNo:
            describe = @"高转速";
            break;
        case MapPointType_IdelNo:
            describe = @"常怠速";
            break;
        default:
            break;
    }
    return describe;
}

- (AbnormalType)getAbnormalTypeByRecordType:(RecordType)recordType{
    if (recordType == RecordType_HeavyBrake) {
        return AbnormalType_HeavyBrake;
    } else if (recordType == RecordType_HeavyStart) {
        return AbnormalType_HeavyStart;
    } else if (recordType == RecordType_HeavyTurnLeft) {
        return AbnormalType_HeavyTurnLeft;
    } else if (recordType == RecordType_HeavyTurnRight) {
        return AbnormalType_HeavyTurnRight;
    } else if (recordType == RecordType_CrazySpeed) {
        return AbnormalType_CrazySpeed;
    } else if (recordType == RecordType_CallPhone) {
        return AbnormalType_CallPhone;
    } else if (recordType == RecordType_AnswerPhone) {
        return AbnormalType_AnswerPhone;
    } else if (recordType == RecordType_SendMessage) {
        return AbnormalType_SendMessage;
    } else if (recordType == RecordType_ReadMessage) {
        return AbnormalType_ReadMessage;
    } else if (recordType == RecordType_UsePhone) {
        return AbnormalType_UsePhone;
    } else if (recordType == RecordType_FatigueDriving) {
        return AbnormalType_FatigueDriving;
    } else {
        //默认急刹车
        return AbnormalType_HeavyBrake;
    }
}

- (AbnormalType)getAbnormalTypeByMapPointType:(MapPointType)mapPointType{
    if (mapPointType == MapPointType_HeavyBrake) {
        return AbnormalType_HeavyBrake;
    } else if (mapPointType == MapPointType_HeavyStart) {
        return AbnormalType_HeavyStart;
    } else if (mapPointType == MapPointType_HeavyTurnLeft) {
        return AbnormalType_HeavyTurnLeft;
    } else if (mapPointType == MapPointType_HeavyTurnRight) {
        return AbnormalType_HeavyTurnRight;
    } else if (mapPointType == MapPointType_CrazySpeed) {
        return AbnormalType_CrazySpeed;
    } else if (mapPointType == MapPointType_CallPhone) {
        return AbnormalType_CallPhone;
    } else if (mapPointType == MapPointType_AnswerPhone) {
        return AbnormalType_AnswerPhone;
    } else if (mapPointType == MapPointType_SendMessage) {
        return AbnormalType_SendMessage;
    } else if (mapPointType == MapPointType_ReadMessage) {
        return AbnormalType_ReadMessage;
    } else if (mapPointType == MapPointType_UsePhone) {
        return AbnormalType_UsePhone;
    } else if (mapPointType == MapPointType_FatigueDriving) {
        return AbnormalType_FatigueDriving;
    } else {
        //默认急刹车
        return AbnormalType_HeavyBrake;
    }
}


- (MapPointType)getMapPointTypeByRecordType:(RecordType)recordType{
    if (recordType == RecordType_HeavyBrake) {
        return  MapPointType_HeavyBrake;
    } else if (recordType == RecordType_HeavyStart) {
        return  MapPointType_HeavyStart;
    } else if (recordType == RecordType_HeavyTurnLeft) {
        return  MapPointType_HeavyTurnLeft;
    } else if (recordType == RecordType_HeavyTurnRight) {
        return  MapPointType_HeavyTurnRight;
    } else if (recordType == RecordType_CrazySpeed) {
        return  MapPointType_CrazySpeed;
    } else if (recordType == RecordType_CallPhone) {
        return  MapPointType_CallPhone;
    } else if (recordType == RecordType_AnswerPhone) {
        return  MapPointType_AnswerPhone;
    } else if (recordType == RecordType_SendMessage) {
        return  MapPointType_SendMessage;
    } else if (recordType == RecordType_ReadMessage) {
        return  MapPointType_ReadMessage;
    } else if (recordType == RecordType_UsePhone) {
        return  MapPointType_UsePhone;
    } else if (recordType == RecordType_FatigueDriving) {
        return  MapPointType_FatigueDriving;
    } else {
        //默认急刹车
        return  MapPointType_HeavyBrake;
    }
}


- (NSString *)getAbnormalDescribe:(AbnormalType)abnormalType{
    if (abnormalType == AbnormalType_HeavyStart) {
        return @"急加速";
    } else if(abnormalType == AbnormalType_HeavyTurnLeft){
        return @"急左转";
    } else if(abnormalType == AbnormalType_HeavyTurnRight){
        return @"急右转";
    } else if (abnormalType == AbnormalType_HeavyBrake){
        return @"急刹车";
    } else if (abnormalType == AbnormalType_CrazySpeed){
        return @"超速";
    } else if(abnormalType == AbnormalType_CallPhone){
        return @"开车打电话";
    } else if (abnormalType == AbnormalType_SendMessage){
        return @"开车发短信";
    } else if (abnormalType == AbnormalType_UsePhone){
        return @"开车玩手机";
    } else if (abnormalType == AbnormalType_FatigueDriving){
        return @"疲劳驾驶";
    }
    return @"";
}

+ (UIColor *)randomColor {
    static BOOL seeded = NO;
    if (!seeded) {
        seeded = YES;
        (time(NULL));
    }
    CGFloat red = (CGFloat)random() / (CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random() / (CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random() / (CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}

- (void)setCanAutoStartLocationServerOnBack:(BOOL)canAuto{
    [self backgroundTask];
    if (canAuto) {
        _canAutoStartLocationServerOnBack = canAuto;
        [self.backgroundTask startAllServer];
    } else {
        _canAutoStartLocationServerOnBack = canAuto;
        [self.backgroundTask stopAllServer];
    }
}


- (NSString *)audioRoute{
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSString *output = [[currentRoute.outputs objectAtIndex:0] portType];
    if ([output isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
        return kAudioSessionManagerDevice_Phone;
    } else if ([output isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
        return kAudioSessionManagerDevice_Speaker;
    } else if ([output isEqualToString:AVAudioSessionPortHeadphones]) {
        return kAudioSessionManagerDevice_Headset;
    } else if ([output isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
               [output isEqualToString:AVAudioSessionPortBluetoothHFP]) {
        return kAudioSessionManagerDevice_Bluetooth;
    } else {
        return kAudioSessionManagerDevice_Unknow;
    }
}

- (ConnectedState)currentConnectedState{
    NSString *output = [self audioRoute];
    if (output == kAudioSessionManagerDevice_Phone) {
        return ConnectedState_Headphones;
    } else if (output == kAudioSessionManagerDevice_Speaker){
        return ConnectedState_Loudspeeker;
    } else if (output == kAudioSessionManagerDevice_Headset){
        return ConnectedState_Wiredheadset;
    } else if (output == kAudioSessionManagerDevice_Bluetooth){
        return ConnectedState_BluetoothHFP;
    } else if (output == kAudioSessionManagerDevice_Unknow){
        return ConnectedState_Unknow;
    } else {
        return ConnectedState_None;
    }
}

- (BOOL)isBluetoothDevice{
    return [self audioRoute] == kAudioSessionManagerDevice_Bluetooth;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 1000001:{
            //来自GPS检测的alertview
            BOOL isOpenDS = self.canAutoStartLocationServerOnBack;
            BOOL isOpenGPS = [DSDriveAndSportRecord sharedRecord].isLocationServicesEnabled && [DSDriveAndSportRecord sharedRecord].isAuthorized;
            switch (buttonIndex) {
                case 0:
                    //取消
                    break;
                case 1:{
                    BOOL needOpenStartLocationServer = YES;
                    BOOL needAlertOpenGPS = NO;
                    if (!isOpenGPS) {
                        needAlertOpenGPS = YES;
                        if (!isOpenDS) {
                            needOpenStartLocationServer = YES;
                        }
                    }else{
                        //开了系统GPS
                        if (!isOpenDS) {
                            needOpenStartLocationServer = YES;
                        }
                    }
                    if (needOpenStartLocationServer) {
                        //打开DS
                        //打开平安行服务
                        NSLog(@"检测平安行服务未启动 用户点击确定开启平安行服务");
                        [[DSDriveAndSportRecord sharedRecord] changeDS:YES];
                    }
                    if (needAlertOpenGPS) {
                        //提示打开GPS
                        NSLog(@"请在“设置-隐私-定位服务”打开定位服务");//需要提示
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}


@end
