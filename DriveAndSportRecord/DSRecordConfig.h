//
//  DSRecordConfig.h
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/10.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSRecordConfig : NSObject

/**
 单列DateFormatter，注意这里使用了threadDictionary，解决线程安全问题
 同一个线程的就创建一次,其他就是调用;
 不同线程,重新创建,这样就不发生线程间资源的竞争的现象了

 @return 日期格式化类
 */
+ (NSDateFormatter *)sharedDateFormatter;

/**
 格式化日期

 @param date 需要进行格式的NSDate对象
 @param format 日期格式
 @return 经过格式化的字符串
 */
+ (NSString *)stringFromDate:(NSDate *)date format:(NSString *)format;

/**
 根据当前时间戳获取journeyId

 @param timeStamp 当前时间戳
 @return journeyId
 */
+ (NSInteger)getJourneyIdByTimeStamp:(NSTimeInterval)timeStamp;

/**
 获取当前手机电量(0 ~ 100)

 @return 手机电量
 */
+ (double)getBatteryLevel;

/**
 获取app版本号

 @return 
 */
+ (NSString*)appVersion;

@end
