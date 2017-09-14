//
//  DSRoadwayModel.h
//  DriveAndSportRecord
//
//  Created by Tristan on 2017/9/12.
//  Copyright © 2017年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DSDefines.h"

@class DSJourneyRecordModel;

@interface DSRoadwayModel : NSObject <NSMutableCopying>

@property(nonatomic,assign) NSInteger roadwayid;              //路途id,主键
@property(nonatomic,assign) NSInteger userid;
@property(nonatomic,assign) NSInteger journeyId;               //行程id,外键
@property(nonatomic,assign) NSInteger roadwaydistance;        //路途距离
@property(nonatomic,assign) double    speeddistance;          //路途距离
@property(nonatomic,assign) long long begintimetag;           //路途开始时间
@property(nonatomic,assign) long long endtimetag;             //路途结束时间
@property(nonatomic,assign) NSInteger roadwaytimespan;        //路途花费时间
@property(nonatomic,assign) RoadwayType roadwaytype;          //路途类型
@property(nonatomic,assign) NSInteger roadwayvalue;           //行程值
@property(nonatomic,assign) BOOL      isDriving;             //行驶中
@property(nonatomic,assign) BOOL      valid;                  //有效标志
@property(nonatomic,assign) BOOL      lowPowner;              //低电量标志
@property(nonatomic,assign) BOOL      isAnalyze;              //
//分析用
@property(nonatomic,strong) DSJourneyRecordModel *beginJourneyRecord;   //开始记录点
@property(nonatomic,strong) DSJourneyRecordModel *endJourneyRecord;     //结束记录点
@property(nonatomic,strong) NSMutableArray *roadwayArray;      //当前路段合并的路段的id数组
@property(nonatomic,strong) NSMutableArray *roadwayTypeArray;  //判断当前路段类型
@property(nonatomic,strong) NSMutableArray *begintimetagArray; //用于合并后请求travelRecord的参数
@property(nonatomic,strong) NSMutableArray *endtimetagArray; //用于合并后请求travelRecord的参数
@property(nonatomic, copy) NSString *driveType;                 // 驾驶类型


@end
