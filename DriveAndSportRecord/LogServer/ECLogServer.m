//
//  ECLogServer.m
//  B2CEC
//
//  Created by Tristan on 16/7/19.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#define kOLD_DAY_COUNT      7

#import "ECLogServer.h"
#import "FMDB.h"


@implementation ECLogServer

- (instancetype)init {
    if (self = [super init]) {
        _fmdb = nil;
        _fmdbQueue = nil;
        _state = NO;
    }
    return self;
}

- (BOOL)open {
    if (_state) {
        return YES;
    }
    if (!_databaseFilePath) {
        _databaseFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"log.sqlite3"];
    }
    if (!_fmdbQueue) {
        _fmdbQueue = [[FMDatabaseQueue alloc] initWithPath:_databaseFilePath];
    }
    if (!_fmdb) {
        _fmdb = [[FMDatabase alloc] initWithPath:_databaseFilePath];
    }
    if ([_fmdb open]) {
        [_fmdb setShouldCacheStatements:YES];
    }
    
    //加载日志表
    NSString *sqlStr = @"create table if not exists log_detail_table (detail_id integer primary key autoincrement, text text, object text, type integer, log_time text, current_thread_info text, time_stamp double)";
    if (![_fmdb tableExists:@"log_detail_table"]) {
        BOOL res = [_fmdb executeUpdate:sqlStr];
        if (!res) {
            return NO;
        }
    }
    _state = YES;
    return YES;
}

- (void)close {
    [_fmdb close];
    _state = NO;
}

- (void)insertDetailTableWithInterface:(NSString *)interface
                                  type:(log_type)type
                                  text:(NSString *)text {
    NSLog(@"%@", text);
    if (!_state) {
        NSLog(@"日志系统未开启");
        return;
    }
    ECLogDetailModel *model = [[ECLogDetailModel alloc] init];
    NSDateFormatter *dateFt = [[NSDateFormatter alloc] init];
    [dateFt setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *time = [dateFt stringFromDate:[NSDate date]];
    //time
    model.time = time;
    //text
    model.text = text;
    //type
    model.type = type;
    //interface
    model.object = interface;
    //threadInfo
    model.currentThreadInfo = [NSThread currentThread].description;
    //timeStamp
    model.timeStamp = [[NSDate date] timeIntervalSince1970];
    [self insertDetailTableWithData:model];
//    [APP_DELEGATE showInfoInBottomWithText:text];
}

- (void)deleteOldRecord {
    NSTimeInterval seconds = 24*60*60*kOLD_DAY_COUNT;
    double currTime = [[NSDate date] timeIntervalSince1970];
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        NSString *sqlStr = [NSString stringWithFormat:@"delete from log_detail_table where time_stamp < ('%lf')", currTime - seconds];
        BOOL result = [db executeUpdate:sqlStr];
        if (result) {
            NSLog(@"7天前日志记录删除成功。");
        } else {
            NSLog(@"7天前日志记录删除失败。");
        }
    }];
}

- (void)deleteAllLog
{
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        NSString *sqlStr = @"delete from log_detail_table";
        BOOL result = [db executeUpdate:sqlStr];
        if (result) {
            NSLog(@"日志记录删除成功。");
        } else {
            NSLog(@"日志记录删除失败。");
        }
    }];
}

#pragma mark - privite 

- (void)insertDetailTableWithData:(ECLogDetailModel *)model {
    __block BOOL insertResult = NO;
    [_fmdbQueue inDatabase:^(FMDatabase *db) {
        NSString *sqlStr = @"insert or replace into log_detail_table(text, object, type, log_time, current_thread_info, time_stamp) values(?, ?, ?, ?, ?, ?)";
        NSNumber *typeNum = [NSNumber numberWithInteger:model.type];
        NSNumber *timeStampNum = [NSNumber numberWithDouble:model.timeStamp];
        insertResult = [db executeUpdate:sqlStr, model.text, model.object, typeNum, model.time, model.currentThreadInfo, timeStampNum];
        if (!insertResult) {
            NSLog(@"日志系统出错");
        }
    }];
}




@end
