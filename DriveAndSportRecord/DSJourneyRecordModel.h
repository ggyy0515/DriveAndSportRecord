//
//  DSJourneyRecordModel.h
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/8.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSDefines.h"

@interface DSJourneyRecordModel : NSObject <NSMutableCopying>
/**
 *  记录id 主键
 */
@property (nonatomic, assign) long long recordId;
/**
 *  行程id 外键
 */
@property (nonatomic, assign) NSInteger journeyId;
/**
 路途id
 */
@property (nonatomic, assign) NSInteger roadwayId;
/**
 *  用户id
 */
@property (nonatomic, assign) NSInteger userId;
/**
 *  记录编号
 */
@property (nonatomic, assign) NSInteger recordIndex;
/**
 *  经度
 */
@property (nonatomic, assign) float longitude;
/**
 *  纬度
 */
@property (nonatomic, assign) float latitude;
/**
 *  海拔
 */
@property (nonatomic, assign) float altitude;
/**
 *  定位精度
 */
@property (nonatomic, assign) NSInteger accuracy;
/**
 *  速度
 */
@property (nonatomic, assign) float speed;
/**
 *  前进方向
 */
@property (nonatomic, assign) float orientation;
/**
 *  是否有效
 */
@property (nonatomic, assign) BOOL valid;
/**
 *  地图类型
 */
@property (nonatomic, assign) MapPointType mapType;
/**
 *  记录类型
 */
@property (nonatomic, assign) RecordType recordType;
/**
 *  电池电量
 */
@property (nonatomic, assign) float batteryLevel;
/**
 *  通话状态
 */
@property (nonatomic, assign) CallState callState;
/**
 *  手机附件连接状态
 */
@property (nonatomic, assign) ConnectedState connectedState;
/**
 *  卫星数
 */
@property (nonatomic, assign) NSInteger satellite;
/**
 *  道路类型
 */
@property (nonatomic, assign) RoadType roadType;
/**
 *  道路限速
 */
@property (nonatomic, assign) NSInteger roadSpeedlimit;
/**
 *  地名
 */
@property (nonatomic, copy) NSString *locality;
/**
 *  时间戳,外键
 */
@property (nonatomic, assign) long long timeStamp;
/**
 *  可读时间(可读时间 yyyy-MM-dd HH:mm:ss)
 */
@property (nonatomic, copy) NSString *time;

@end
