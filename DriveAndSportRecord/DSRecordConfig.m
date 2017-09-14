//
//  DSRecordConfig.m
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/10.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSRecordConfig.h"

@implementation DSRecordConfig

+ (NSDateFormatter *)sharedDateFormatter
{
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter = threadDictionary[@"codateformatter"];
    if(!dateFormatter){
        @synchronized(self){
            if(!dateFormatter){
                dateFormatter = [[NSDateFormatter alloc] init];
                threadDictionary[@"codateformatter"] = dateFormatter;
            }
        }
    }
    
    return dateFormatter;
}

+ (NSString *)stringFromDate:(NSDate *)date format:(NSString *)format {
    NSDateFormatter *dateFormatter = [self sharedDateFormatter];
    [dateFormatter setDateFormat:format];
    NSString *str = [dateFormatter stringFromDate:date];
    return str;
}


+ (NSInteger)getJourneyIdByTimeStamp:(NSTimeInterval)timeStamp {
    NSString *dateStr = [self stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeStamp] format:@"yyyyMMdd"];
    return dateStr.integerValue;
}

+ (double)getBatteryLevel {
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    return [UIDevice currentDevice].batteryLevel * 100;
}


+ (NSString*)appVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

@end
