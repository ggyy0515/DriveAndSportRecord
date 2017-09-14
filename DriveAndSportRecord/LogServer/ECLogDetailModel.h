//
//  ECLogDetailModel.h
//  B2CEC
//
//  Created by Tristan on 16/7/19.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  日志类型
 */
typedef NS_ENUM(NSInteger, log_type) {
    /**
     *  错误
     */
    type_error  = 1,
    /**
     *  调试
     */
    type_debug  = 2,
    /**
     *  信息
     */
    type_info = 3,
};


@interface ECLogDetailModel : NSObject


@property (nonatomic, assign) NSInteger      detail_id;             //日志详情ID
@property (nonatomic, copy) NSString         *text;                 //日志描述
@property (nonatomic, copy) NSString         *object;               //日志对象
@property (nonatomic, assign) log_type       type;                  //日志类型
@property (nonatomic, copy) NSString         *time;                 //日志时间
@property (nonatomic, copy) NSString         *currentThreadInfo;                 //当前线程信息
@property (nonatomic, assign) double         timeStamp;             //时间戳


@end
