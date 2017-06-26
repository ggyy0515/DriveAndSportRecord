//
//  DSJourneyModel.h
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/4.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSJourneyModel : NSObject <NSMutableCopying>
/**
 *  行程id
 */
@property (nonatomic, assign) NSInteger journeyId;
/**
 *  用户id
 */
@property (nonatomic, assign) NSInteger userId;
/**
 *  距离
 */
@property (nonatomic, assign) float distance;
/**
 *  时间花销
 */
@property (nonatomic, assign) NSInteger timeSpend;
/**
 *  平均速度
 */
@property (nonatomic, assign) float averageSpeed;
/**
 *  最大速度
 */
@property (nonatomic, assign) float maxSpeed;

@end
