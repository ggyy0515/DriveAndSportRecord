//
//  DSJourneyModel.m
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/4.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import "DSJourneyModel.h"



@implementation DSJourneyModel

- (id)mutableCopyWithZone:(NSZone *)zone {
    DSJourneyModel *copyModel = [[[self class] allocWithZone:zone] init];
    copyModel.journeyId = _journeyId;
    copyModel.userId = _userId;
    copyModel.distance = _distance;
    copyModel.timeSpend = _timeSpend;
    copyModel.averageSpeed = _averageSpeed;
    copyModel.maxSpeed = _maxSpeed;
    return copyModel;
}


@end
