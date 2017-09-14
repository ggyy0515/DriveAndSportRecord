//
//  ECLogServer.h
//  B2CEC
//
//  Created by Tristan on 16/7/19.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECLogDetailModel.h"

@class FMDatabase;
@class FMDatabaseQueue;

@interface ECLogServer : NSObject

@property (nonatomic, assign, readonly) BOOL state;

@property (nonatomic, copy) NSString *databaseFilePath;

@property (nonatomic, readonly) FMDatabase *fmdb;

@property (nonatomic, readonly) FMDatabaseQueue *fmdbQueue;


/**
 *  开启日志服务
 *
 *  @return 是否成功
 */
- (BOOL)open;
/**
 *  关闭日志服务
 */
- (void)close;
/**
 *  插入日志
 *
 *  @param interface 当前页面或接口
 *  @param type      日志类型
 *  @param text      描述信息
 */
- (void)insertDetailTableWithInterface:(NSString *)interface
                                  type:(log_type)type
                                  text:(NSString *)text;
/**
 *  删除n天以前的旧日志(默认7天)
 */ 
- (void)deleteOldRecord;
/**
 *  删除所有日志
 */
- (void)deleteAllLog;

@end
