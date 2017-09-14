//
//  DSGlobals.h
//  DriveAndSportRecord
//
//  Created by Tristan on 2017/9/1.
//  Copyright © 2017年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKReverseGeocoder.h>
#import <MapKit/MKPlacemark.h>
#import <UIKit/UIKit.h>

#import "gpscorrect.h"
#import "DSBackgroungTask.h"
#import "DSDataAnalyze.h"
#import "DSDatabaseService.h"
#import "DSDefines.h"

@interface DSGlobals : NSObject {
    
    NSDate                  *saveDate;
    
    NSTimer                 *changeProgressTimer;
    
    DSDatabaseService       *databaseService;
    DSBackgroungTask        *backgroundTask;
    DSDataAnalyze           *dataAnalyze;
}
@property (nonatomic, assign) BOOL          canAutoStartLocationServerOnBack,isLogServer;
@property (nonatomic, copy) NSString        *serverIP,*serverPort,*serverUrl;
@property (nonatomic, copy) NSString        *version,*osType;
@property (nonatomic, strong) NSDictionary  *speedUpDict,*slowDownDict;
@property (nonatomic, strong) NSArray       *orderedSpeedUpArray;
@property (nonatomic, assign) float         turnSpeed,turnAngle;
@property (nonatomic, assign) NSInteger     driveInterval,walkInterval,maxThreadNum,maxPackage,tireDrive;
@property (nonatomic, assign) BOOL          isRefreshed,isBingding,autoUpload,isDebug;
@property (nonatomic, strong) NSDate        *refreshDate;

+ (instancetype)sharedGlobals;
- (DSDatabaseService *)databaseService;
- (DSBackgroungTask *)backgroundTask;
- (DSDataAnalyze *)dataAnalyze;
- (void)setUserId:(NSInteger)userId;

//程序进入前台
- (void)didBecomeActive;

- (void)checkLocationServer;


//保存配置信息
- (void)saveConfigInfo;
//获取本地的配置信息
- (void)getConfigInfo;

- (void)showRoadToast;

- (void)getAllSetinfo;

- (void)getOrderedSpeedUpArray;

+ (CLLocationCoordinate2D) convertWgs84ToGcj02:(double)originlongitude andlatitude:(double)originlatitude;

+ (OrientationType)getOrientationTypeByCourse:(NSInteger)course;

+ (NSString *)getTimeIntervalToStr:(NSTimeInterval)timetag;

+ (NSString *)getTimeIntervalToStr1:(NSTimeInterval)timetag;

+ (NSString *)getTimeIntervalToStr2:(NSTimeInterval)timetag;

+ (NSString *)getTimeIntervalToString:(NSTimeInterval)timetag;

+ (NSString *)getTimeIntervalToHM:(NSTimeInterval)timetag;

+ (NSString *)getTimeIntervalToDate:(NSTimeInterval)timetag;

- (NSString *)getMapPointTypeDescribe:(MapPointType)mapPointType;

- (AbnormalType)getAbnormalTypeByMapPointType:(MapPointType)mapPointType;

- (NSString *)getAbnormalDescribe:(AbnormalType)abnormalType;

+ (NSInteger)getTravelIdByTimeInterval:(NSTimeInterval)timetag;

+ (NSString *)getTravelIdByDate:(NSDate *)date;

+ (NSInteger)getRoadwayIdByTimeInterval:(NSTimeInterval)timetag currentIndex:(NSInteger)index;

+ (UIColor *)randomColor;

- (AbnormalType)getAbnormalTypeByRecordType:(RecordType)recordType;

- (MapPointType)getMapPointTypeByRecordType:(RecordType)recordType;

- (ConnectedState)currentConnectedState;

- (BOOL)isBluetoothDevice;

@end
