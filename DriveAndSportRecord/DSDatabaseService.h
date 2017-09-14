//
//  DSDatabaseService.h
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/4.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FMDB.h"

@class DSJourneyModel;
@class DSJourneyRecordModel;
@class DSEventInfoModel;
@class DSEventInfoModel;


@interface DSDatabaseService : NSObject
/**
 *  存储器状态
 */
@property (nonatomic, assign, readonly) BOOL state;
/**
 *  数据库文件路径
 */
@property (nonatomic, copy) NSString *databaseFilePath;

@property (nonatomic, readonly) FMDatabase *fmdb;

@property (nonatomic, readonly) FMDatabaseQueue *fmdbQueue;


//开启数据服务，并返回成功信息
- (BOOL)open;
//关闭数据服务
- (void)close;

#pragma mark - Save Model
/**
 *  保存DSJourneyModel
 *
 *  @param model DSJourneyModel
 *
 *  @return 成功标识
 */
- (BOOL)saveDSJourneyModel:(DSJourneyModel *)model;
/**
 *  保存DSJourneyModel，提供此方法便于在业务逻辑层控制回滚
 *
 *  @param model DSJourneyModel
 *  @param db    db
 *
 *  @return 成功标识
 */
- (BOOL)saveDSJourneyModel:(DSJourneyModel *)model fmdb:(FMDatabase *)db;
/**
 *  保存DSJourneyRecordModel
 *
 *  @param model DSJourneyRecordModel
 *
 *  @return 成功标识
 */
- (BOOL)saveDSJourneyRecordModel:(DSJourneyRecordModel *)model;
/**
 *  保存DSJourneyRecordModel，提供此方法便于在业务逻辑层控制回滚
 *
 *  @param model DSJourneyRecordModel
 *  @param db    db
 *
 *  @return 成功标识
 */
- (BOOL)saveDSJourneyRecordModel:(DSJourneyRecordModel *)model fmdb:(FMDatabase *)db;
/**
 保存DSEventInfoModel

 @param eventInfo DSEventInfoModel
 @return 成功标识
 */
- (BOOL)saveEventInfoModel:(DSEventInfoModel *)eventInfo;
/**
 保存DSEventInfoModel 提供此方法便于在业务逻辑层控制回滚

 @param eventInfo DSEventInfoModel
 @param db db
 @return 成功标识
 */
- (BOOL)saveEventInfoModel:(DSEventInfoModel *)eventInfo fmdb:(FMDatabase *)db;




//获取是否低电标识
- (DSEventInfoModel *)getLastLowPownerEventInfoByEventDate:(NSInteger)eventDate UserId:(NSInteger)userid;

@end
