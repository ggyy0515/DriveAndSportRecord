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
#import "DSEventInfoModel.h"

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
    sqlStr = @"create table if not exists journeyrecord(id long long primary key, recordid long long, journeyid integer not null, roadwayid integer not null, userid integer not null, recordindex integer, longitude float not null, latitude float not null, altitude float not null, accuracy integer, speed float not null, orientation integer, valid integer default 1, maptype integer default 1, recordtype integer not null, batterylevel float, callstate integer, connectedstate integer, satellite integer, roadtype integer, roadspeedlimit integer, locality text, timestamp long long, time text)";
    if (![_fmdb tableExists:@"journeyrecord"]) {
        BOOL res = [_fmdb executeUpdate:sqlStr];
        if (!res) {
            NSLog(@"failed to create journeyrecord");
        }
    }
    
    
    
    
    
    
    //------------------- 以下为分析产生的数据-------------------------//
    
    //3.roadwayinfo 路途信息
    //id(主键 等于roadwayid与userid拼接) roadwayid (路途id) userid（用户ID）journeyid（行程id，外键）roadwaydistance (路途距离) speeddistance (路途距离) begintimetag（路途开始时间）endtimetag(路途结束时间) roadwaytimespan（路途花费时间）roadwaytype（路途类型）roadwayvalue(行程值) isdriving(行驶中) valid（有效标志） lowpower(电量) isanalyze(是否分析)
    sqlStr = @"create table if not exists roadwayinfo(id long long primary key, roadwayid integer, userid integer, journeyid integer not null, roadwaydistance float not null, speeddistance float, begintimetag long long not null, endtimetag long long not null, roadwaytimespan integer not null, roadwaytype integer not null, roadwayvalue integer default -1, valid integer, lowpower integer, isanalyze integer)";
    
    if (![_fmdb tableExists:@"roadwayinfo"]) {
        BOOL res = [_fmdb executeUpdate:sqlStr];
        if (!res) {
            NSLog(@"failed to create roadwayinfo");
        }
    }
    
    //4.abnormalinfo 异常驾驶点
    //abnormalid (异常id) userid（用户ID） travelid（行程id，外键） abnormaltype（异常类型）abnormalcount(异常次数)
    sqlStr = @"create table if not exists abnormalinfo(abnormalid integer primary key autoincrement,userid integer,travelid integer not null,abnormaltype integer not null,abnormalcount integer,tripterminaltype integer)";
    
    if (![_fmdb tableExists:@"abnormalinfo"]) {
        BOOL res = [_fmdb executeUpdate:sqlStr];
        if (!res) {
            NSLog(@"failed to create abnormalinfo");
        }
    }
    
    //5.event 事件表
    //eventid主键，userid用户id,type事件类型，value事件值，eventtype 日期,timetag时间，descript描述
    sqlStr = @"create table if not exists eventinfo(eventid integer primary key autoincrement,userid integer,eventtype integer,eventvalue integer,eventdate integer,timetag long long not null,descript text)";
    
    if (![_fmdb tableExists:@"eventinfo"]) {
        BOOL res = [_fmdb executeUpdate:sqlStr];
        if (!res) {
            NSLog(@"failed to create eventinfo");
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
        NSString *sqlStr = @"insert or ignore into journeyrecord (id, recordid, journeyid, roadwayid, userid, recordindex, longitude, latitude, altitude, accuracy, speed, orientation, valid, maptype, recordtype, batterylevel, callstate, connectedstate, satellite, roadtype, roadspeedlimit, locality, timestamp, time) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        NSNumber *nid = [NSNumber numberWithLongLong:[[NSString stringWithFormat:@"%lld%ld", model.recordId, (long)model.userId] longLongValue]];
        NSNumber *nrecordId = [NSNumber numberWithLongLong:model.recordId];
        NSNumber *njourneyId = [NSNumber numberWithInteger:model.journeyId];
        NSNumber *nroadwayId = [NSNumber numberWithInteger:model.roadwayId];
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
        saveResult = [db executeUpdate:sqlStr, nid, nrecordId, njourneyId, nroadwayId, nuserId, nrecordIndex, nlongitude, nlatitude, naltitude, naccuracy, nspeed, norientation, nvalid, nmapType, nrecordType, nbatteryLevel, ncallState, nconnectedState, nsatellite, nroadType, nroadSpeedLimit, model.locality, ntimeStamp, model.time];
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
    NSString *sqlStr = @"insert or replace into journeyrecord (id, recordid, journeyid, roadwayid, userid, recordindex, longitude, latitude, altitude, accuracy, speed, orientation, valid, maptype, recordtype, batterylevel, callstate, connectedstate, satellite, roadtype, roadspeedlimit, locality, timestamp, time) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    NSNumber *nid = [NSNumber numberWithLongLong:[[NSString stringWithFormat:@"%lld%ld", model.recordId, (long)model.userId] longLongValue]];
    NSNumber *nrecordId = [NSNumber numberWithLongLong:model.recordId];
    NSNumber *njourneyId = [NSNumber numberWithInteger:model.journeyId];
    NSNumber *nroadwayId = [NSNumber numberWithInteger:model.roadwayId];
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
    BOOL saveResult = [db executeUpdate:sqlStr, nid, nrecordId, njourneyId, nroadwayId, nuserId, nrecordIndex, nlongitude, nlatitude, naltitude, naccuracy, nspeed, norientation, nvalid, nmapType, nrecordType, nbatteryLevel, ncallState, nconnectedState, nsatellite, nroadType, nroadSpeedLimit, model.locality, ntimeStamp, model.time];
    if (!saveResult) {
        NSLog(@"saveDSJourneyRecordModel fmdb: %@", db.lastErrorMessage);
    }
    return saveResult;
}

- (BOOL)saveEventInfoModel:(DSEventInfoModel *)eventInfo {
    __block BOOL saveResult = NO;
    
    if (eventInfo.userId == 0) {
        return TRUE;
    }
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        NSNumber *nuserid = [NSNumber numberWithInteger:eventInfo.userId];
        NSNumber *neventType = [NSNumber numberWithInteger:eventInfo.eventType];
        NSNumber *neventValue = [NSNumber numberWithInteger:eventInfo.eventValue];
        NSNumber *neventDate = [NSNumber numberWithInteger:eventInfo.eventDate];
        NSNumber *ntimetag = [NSNumber numberWithLongLong:eventInfo.timetag];
        NSString *sql = @"insert or replace into eventinfo(userid,eventtype,eventvalue,eventdate,timetag,descript) values (?, ?, ?, ?, ?, ?)";
        saveResult = [db executeUpdate:sql,nuserid,neventType,neventValue,neventDate,ntimetag,eventInfo.decript];
        if (!saveResult) {
            NSLog(@"error to saveEventInfoModel FMDB:%@",db.lastErrorMessage);
        }
    }];
    return saveResult;
}


- (BOOL)saveEventInfoModel:(DSEventInfoModel *)eventInfo fmdb:(FMDatabase *)db {
    BOOL saveResult = NO;
    NSNumber *nuserid = [NSNumber numberWithInteger:eventInfo.userId];
    NSNumber *neventType = [NSNumber numberWithInteger:eventInfo.eventType];
    NSNumber *neventValue = [NSNumber numberWithInteger:eventInfo.eventValue];
    NSNumber *neventDate = [NSNumber numberWithInteger:eventInfo.eventDate];
    NSNumber *ntimetag = [NSNumber numberWithLongLong:eventInfo.timetag];
    NSString *sql = @"insert or replace into eventinfo(userid,eventtype,eventvalue,eventdate,timetag,descript) values (?, ?, ?, ?, ?, ?)";
    saveResult = [db executeUpdate:sql,nuserid,neventType,neventValue,neventDate,ntimetag,eventInfo.decript];
    if (!saveResult) {
        NSLog(@"error to saveEventInfoModel FMDB:%@",db.lastErrorMessage);
    }
    return !saveResult;
}

- (DSEventInfoModel *)getLastLowPownerEventInfoByEventDate:(NSInteger)eventDate UserId:(NSInteger)userid {
    __block  DSEventInfoModel *eventInfoModel = nil;
    WEAK_SELF
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        //插入成功后返回
        NSString *sqlStr = [NSString stringWithFormat:@"select * from eventinfo where eventdate = %ld and userid = %ld and eventtype = %d order by timetag desc limit 1",(long)eventDate,(long)userid,EventType_Powner];
        FMResultSet *stmt = [db executeQuery:sqlStr];
        while ([stmt next]) {
            eventInfoModel = [[DSEventInfoModel alloc] init];
            [weakSelf getEventInfoFromSTMT:stmt into:eventInfoModel];
        }
        [stmt close];
        if (!eventInfoModel) {
            NSLog(@"getLastLowPownerEventInfo -nil");
        }
        
    }];
    return eventInfoModel;
}


- (void)getEventInfoFromSTMT:(FMResultSet *)stmt into:(DSEventInfoModel *)eventInfo{
    NSInteger eventId = [stmt intForColumnIndex:0];
    NSInteger userId = [stmt intForColumnIndex:1];
    int eventtype = [stmt intForColumnIndex:2];
    int eventvalue = [stmt intForColumnIndex:3];
    NSInteger eventdate = [stmt intForColumnIndex:4];
    long long timetag = [stmt longLongIntForColumnIndex:5];
    NSString  *decript = [stmt stringForColumnIndex:6];
    //对象封装
    eventInfo.eventId = eventId;
    eventInfo.userId = userId;
    eventInfo.eventType = eventtype;
    eventInfo.eventValue = eventvalue;
    eventInfo.eventDate = eventdate;
    eventInfo.timetag = timetag;
    eventInfo.decript = decript;
}


@end
