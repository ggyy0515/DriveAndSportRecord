//
//  DSDatabaseService.m
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/4.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import "DSDatabaseService.h"
#import "DSDefines.h"
#import "DSJourneyModel.h"
#import "DSJourneyRecordModel.h"

@implementation DSDatabaseService

#pragma mark - Service Life Cycle

- (instancetype)init {
    if (self = [super init]) {
        _fmdb = nil;
        _fmdbQueue = nil;
        _databaseFilePath = nil;
        _state = NO;
    }
    return self;
}

- (BOOL)open {
    if (_state) {
        return YES;
    }
    if (!_databaseFilePath) {
         _databaseFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"DSRecord.sqlite3"];
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
    

    
    //1.创建行程信息表 journeyinfo
    //id(主键 等于journeyid与userid拼接) journeyid(行程id) userid(用户id) distance(距离) timespend(时间花销) averagespeed(平均速度) maxspeed(最大速度)
    NSString *sqlStr = @"create table if not exists journeyinfo(id long long primary key, journeyid integer, userid integer default 0, distance float default 0.0, timespend integer default 0, averagespeed float default 0.0, maxspeed float default 0.0)";
    if (![_fmdb tableExists:@"journeyinfo"]) {
        BOOL res = [_fmdb executeUpdate:sqlStr];
        if (!res) {
            NSLog(@"failed to create journeyinfo");
        }
    }
    //2.创建行程详情表 journeyrecord
    //id(主键 等于recordid与userid拼接) recordid(记录id) journeyid(行程id) //roadwayid(路途id)// userid（用户ID）recordindex（记录索引）longitude（经度）latitude（纬度）altitude（海拔）accuracy (精确度) speed（速度）orientation（前进方向) valid（是否有效） maptype（地图标记类型） recordtype（记录点类型） batteryLevel（电池电量）callstate（电话状态）connectedstate（手机附件链接状态）satellite（卫星数）roadtype（道路类型）roadspeedlimit（道路限速） locality (地名解析) timestamp(时间戳) time(可读时间 yyyy-MM-dd HH:mm:ss) //issecret (隐秘行程)//
    sqlStr = @"create table if not exists journeyrecord(id long long primary key, recordid long long, journeyid integer not null, userid integer not null, recordindex integer, longitude float not null, latitude float not null, altitude float not null, accuracy integer, speed float not null, orientation integer, valid integer default 1, maptype integer default 1, recordtype integer not null, batterylevel float, callstate integer, connectedstate integer, satellite integer, roadtype integer, roadspeedlimit integer, locality text, timestamp long long, time)";
    if (![_fmdb tableExists:@"journeyrecord"]) {
        BOOL res = [_fmdb executeUpdate:sqlStr];
        if (!res) {
            NSLog(@"failed to create journeyrecord");
        }
    }
    _state = YES;
    return YES;
}

- (void)close {
    [_fmdb close];
    [_fmdbQueue close];
    _state = NO;
}


#pragma mark - Save Model

- (BOOL)saveDSJourneyModel:(DSJourneyModel *)model {
//    typeof(self) __weak weakSelf = self;
    __block BOOL saveResult = NO;
    [_fmdbQueue inDatabase:^(FMDatabase *db) {
        NSString *sqlStr = @"insert or ignore into journeyinfo (id, journeyid, userid, distance, timespend, averagespeed, maxspeed) values (?, ?, ?, ?, ?, ?, ?)";
        NSNumber *nid = [NSNumber numberWithLongLong:[[NSString stringWithFormat:@"%ld%ld", (long)model.journeyId, (long)model.userId] longLongValue]];
        NSNumber *njourneyId = [NSNumber numberWithInteger:model.journeyId];
        NSNumber *nuserId = [NSNumber numberWithInteger:model.userId];
        NSNumber *ndistance = [NSNumber numberWithFloat:model.distance];
        NSNumber *ntimeSpend = [NSNumber numberWithInteger:model.timeSpend];
        NSNumber *naverageSpeed = [NSNumber numberWithFloat:model.averageSpeed];
        NSNumber *nmaxSpeed = [NSNumber numberWithFloat:model.maxSpeed];
        saveResult = [db executeUpdate:sqlStr, nid, njourneyId, nuserId, ndistance, ntimeSpend, naverageSpeed, nmaxSpeed];
        if (!saveResult) {
            NSLog(@"saveDSJourneyModel:%@", db.lastErrorMessage);
        }
    }];
    return saveResult;
}

- (BOOL)saveDSJourneyModel:(DSJourneyModel *)model fmdb:(FMDatabase *)db {
    NSString *sqlStr = @"insert or replace into journeyinfo (id, journeyid, userid, distance, timespend, averagespeed, maxspeed) values (?, ?, ?, ?, ?, ?, ?)";
    NSNumber *nid = [NSNumber numberWithLongLong:[[NSString stringWithFormat:@"%ld%ld", (long)model.journeyId, (long)model.userId] longLongValue]];
    NSNumber *njourneyId = [NSNumber numberWithInteger:model.journeyId];
    NSNumber *nuserId = [NSNumber numberWithInteger:model.userId];
    NSNumber *ndistance = [NSNumber numberWithFloat:model.distance];
    NSNumber *ntimeSpend = [NSNumber numberWithInteger:model.timeSpend];
    NSNumber *naverageSpeed = [NSNumber numberWithFloat:model.averageSpeed];
    NSNumber *nmaxSpeed = [NSNumber numberWithFloat:model.maxSpeed];
    BOOL saveResult = [db executeUpdate:sqlStr, nid, njourneyId, nuserId, ndistance, ntimeSpend, naverageSpeed, nmaxSpeed];
    if (!saveResult) {
        NSLog(@"saveDSJourneyModel fmdb: %@", db.lastErrorMessage);
    }
    return saveResult;
}

- (BOOL)saveDSJourneyRecordModel:(DSJourneyRecordModel *)model {
    __block BOOL saveResult = NO;
    [_fmdbQueue inDatabase:^(FMDatabase *db) {
        NSString *sqlStr = @"insert or ignore into journeyrecord (id, recordid, userid, recordindex, longitude, latitude, altitude, accuracy, speed, orientation, valid, maptype, recordtype, batterylevel, callstate, connectedstate, satellite, roadtype, roadspeedlimit, locality, timestamp, time) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        NSNumber *nid = [NSNumber numberWithLongLong:[[NSString stringWithFormat:@"%lld%ld", model.recordId, (long)model.userId] longLongValue]];
        NSNumber *nrecordId = [NSNumber numberWithLongLong:model.recordId];
        NSNumber *nuserId = [NSNumber numberWithInteger:model.userId];
        NSNumber *nrecordIndex = [NSNumber numberWithInteger:model.recordIndex];
        NSNumber *nlongitude = [NSNumber numberWithFloat:model.longitude];
        NSNumber *nlatitude = [NSNumber numberWithFloat:model.latitude];
        NSNumber *naltitude = [NSNumber numberWithFloat:model.altitude];
        NSNumber *naccuracy = [NSNumber numberWithInteger:model.accuracy];
        NSNumber *nspeed = [NSNumber numberWithFloat:model.speed];
        NSNumber *norientation = [NSNumber numberWithFloat:model.orientation];
        NSNumber *nvalid = [NSNumber numberWithBool:model.valid];
        NSNumber *nmapType = [NSNumber numberWithInteger:model.mapType];
        NSNumber *nrecordType = [NSNumber numberWithInteger:model.recordType];
        NSNumber *nbatteryLevel = [NSNumber numberWithFloat:model.batteryLevel];
        NSNumber *ncallState = [NSNumber numberWithInteger:model.callState];
        NSNumber *nconnectedState = [NSNumber numberWithInteger:model.connectedState];
        NSNumber *nsatellite = [NSNumber numberWithInteger:model.satellite];
        NSNumber *nroadType = [NSNumber numberWithInteger:model.roadType];
        NSNumber *nroadSpeedLimit = [NSNumber numberWithInteger:model.roadSpeedlimit];
        NSNumber *ntimeStamp = [NSNumber numberWithLongLong:model.timeStamp];
        saveResult = [db executeUpdate:sqlStr, nid, nrecordId, nuserId, nrecordIndex, nlongitude, nlatitude, naltitude, naccuracy, nspeed, norientation, nvalid, nmapType, nrecordType, nbatteryLevel, ncallState, nconnectedState, nsatellite, nroadType, nroadSpeedLimit, model.locality, ntimeStamp, model.time];
        if (!saveResult) {
            NSLog(@"saveDSJourneyRecordModel:%@", db.lastErrorMessage);
        }
    }];
    return saveResult;
}

- (BOOL)saveDSJourneyRecordModel:(DSJourneyRecordModel *)model fmdb:(FMDatabase *)db {
    if (!model || model.recordId == 0) {
        return NO;
    }
    NSString *sqlStr = @"insert or replace into journeyrecord (id, recordid, userid, recordindex, longitude, latitude, altitude, accuracy, speed, orientation, valid, maptype, recordtype, batterylevel, callstate, connectedstate, satellite, roadtype, roadspeedlimit, locality, timestamp, time) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    NSNumber *nid = [NSNumber numberWithLongLong:[[NSString stringWithFormat:@"%lld%ld", model.recordId, (long)model.userId] longLongValue]];
    NSNumber *nrecordId = [NSNumber numberWithLongLong:model.recordId];
    NSNumber *nuserId = [NSNumber numberWithInteger:model.userId];
    NSNumber *nrecordIndex = [NSNumber numberWithInteger:model.recordIndex];
    NSNumber *nlongitude = [NSNumber numberWithFloat:model.longitude];
    NSNumber *nlatitude = [NSNumber numberWithFloat:model.latitude];
    NSNumber *naltitude = [NSNumber numberWithFloat:model.altitude];
    NSNumber *naccuracy = [NSNumber numberWithInteger:model.accuracy];
    NSNumber *nspeed = [NSNumber numberWithFloat:model.speed];
    NSNumber *norientation = [NSNumber numberWithFloat:model.orientation];
    NSNumber *nvalid = [NSNumber numberWithBool:model.valid];
    NSNumber *nmapType = [NSNumber numberWithInteger:model.mapType];
    NSNumber *nrecordType = [NSNumber numberWithInteger:model.recordType];
    NSNumber *nbatteryLevel = [NSNumber numberWithFloat:model.batteryLevel];
    NSNumber *ncallState = [NSNumber numberWithInteger:model.callState];
    NSNumber *nconnectedState = [NSNumber numberWithInteger:model.connectedState];
    NSNumber *nsatellite = [NSNumber numberWithInteger:model.satellite];
    NSNumber *nroadType = [NSNumber numberWithInteger:model.roadType];
    NSNumber *nroadSpeedLimit = [NSNumber numberWithInteger:model.roadSpeedlimit];
    NSNumber *ntimeStamp = [NSNumber numberWithLongLong:model.timeStamp];
    BOOL saveResult = [db executeUpdate:sqlStr, nid, nrecordId, nuserId, nrecordIndex, nlongitude, nlatitude, naltitude, naccuracy, nspeed, norientation, nvalid, nmapType, nrecordType, nbatteryLevel, ncallState, nconnectedState, nsatellite, nroadType, nroadSpeedLimit, model.locality, ntimeStamp, model.time];
    if (!saveResult) {
        NSLog(@"saveDSJourneyRecordModel fmdb: %@", db.lastErrorMessage);
    }
    return saveResult;
}



@end
