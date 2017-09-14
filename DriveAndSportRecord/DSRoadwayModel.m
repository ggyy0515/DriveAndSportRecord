//
//  DSRoadwayModel.m
//  DriveAndSportRecord
//
//  Created by Tristan on 2017/9/12.
//  Copyright © 2017年 Tristan. All rights reserved.
//

#import "DSRoadwayModel.h"
#import "DSJourneyRecordModel.h"

@implementation DSRoadwayModel

- (instancetype)init {
    if (self = [super init]) {
        _lowPowner = NO;
        _isAnalyze = NO;
    }
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    DSRoadwayModel *roadModel = [DSRoadwayModel allocWithZone:zone];
    roadModel.roadwayid = _roadwayid;
    roadModel.userid = _userid;
    roadModel.journeyId = _journeyId;
    roadModel.roadwaydistance = _roadwaydistance;
    roadModel.speeddistance = _speeddistance;
    roadModel.begintimetag = _begintimetag;
    roadModel.endtimetag = _endtimetag;
    roadModel.roadwaytimespan = _roadwaytimespan;
    roadModel.roadwaytype = _roadwaytype;
    roadModel.roadwayvalue = _roadwayvalue;
    roadModel.isDriving = _isDriving;
    roadModel.valid = _valid;
    roadModel.lowPowner = _lowPowner;
    roadModel.isAnalyze = _isAnalyze;
    roadModel.beginJourneyRecord = _beginJourneyRecord.mutableCopy;
    roadModel.endJourneyRecord = _endJourneyRecord.mutableCopy;
    roadModel.roadwayArray = _roadwayArray.mutableCopy;
    roadModel.roadwayTypeArray = _roadwayTypeArray.mutableCopy;
    roadModel.begintimetagArray = _begintimetagArray.mutableCopy;
    roadModel.endtimetagArray = _endtimetagArray.mutableCopy;
    roadModel.driveType = _driveType;
    return roadModel;
}

@end
