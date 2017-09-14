//
//  DSJourneyRecordModel.m
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/8.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import "DSJourneyRecordModel.h"

@implementation DSJourneyRecordModel

- (id)mutableCopyWithZone:(NSZone *)zone {
    DSJourneyRecordModel *copyModel = [[DSJourneyRecordModel allocWithZone:zone] init];
    copyModel.recordId = _recordId;
    copyModel.journeyId = _journeyId;
    copyModel.roadwayId = _roadwayId;
    copyModel.userId = _userId;
    copyModel.recordIndex = _recordIndex;
    copyModel.longitude = _longitude;
    copyModel.latitude = _latitude;
    copyModel.altitude = _altitude;
    copyModel.accuracy = _accuracy;
    copyModel.speed = _speed;
    copyModel.orientation = _orientation;
    copyModel.valid = _valid;
    copyModel.mapType = _mapType;
    copyModel.recordType = _recordType;
    copyModel.batteryLevel = _batteryLevel;
    copyModel.callState = _callState;
    copyModel.connectedState = _connectedState;
    copyModel.satellite = _satellite;
    copyModel.roadType = _roadType;
    copyModel.roadSpeedlimit = _roadSpeedlimit;
    copyModel.locality = _locality;
    copyModel.timeStamp = _timeStamp;
    copyModel.time = _time;
    return copyModel;
}


@end
