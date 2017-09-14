//
//  DSDefines.h
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/8.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#ifndef DSDefines_h
#define DSDefines_h

#pragma mark - Enums

//车辆前进方向
typedef enum {
    OrientationType_East = 1,  //东
    OrientationType_South = 2, //南
    OrientationType_West = 3,  //西
    OrientationType_North = 4, //北
} OrientationType;

//标记类型
typedef enum {
    //默认
    MapPointType_UnKnow = 0,
    //起点
    MapPointType_BeginPoint = 1,
    //终点
    MapPointType_EndPoint = 2,
    //停止点
    MapPointType_StopPoint = 3,
    //路途点（分段起点和终点）
    MapPointType_RoadWayPoint = 4,
    //走路点
    MapPointType_WalkPoint = 5,
    //开车点
    MapPointType_DriverPoint = 6,
    //急刹车
    MapPointType_HeavyBrake = 7,
    //急加速
    MapPointType_HeavyStart = 8,
    //急左转
    MapPointType_HeavyTurnLeft = 9,
    //急右转
    MapPointType_HeavyTurnRight = 10,
    //超速
    MapPointType_CrazySpeed = 11,
    //开车打电话
    MapPointType_CallPhone = 12,
    //开车接电话
    MapPointType_AnswerPhone = 13,
    //开车发短信
    MapPointType_SendMessage = 14,
    //开车读短信
    MapPointType_ReadMessage = 15,
    //开车玩手机
    MapPointType_UsePhone = 16,
    //疲劳驾驶
    MapPointType_FatigueDriving = 17,
    //转速不匹配
    MapPointType_SpeedNotMatch = 18,
    //高转速
    MapPointType_HighRotationNo = 19,
    //常怠速
    MapPointType_IdelNo = 20,
    //低电量
    MapPointType_LowPowner = 21,
    //变道
    MapPointType_ChangeRoad = 22,
} MapPointType;

//标记类型
typedef enum {
    //走路
    RecordType_Walk = 1,
    //驾车
    RecordType_Drive = 2,
    //停止
    RecordType_Stop = 3,
    //急刹车
    RecordType_HeavyBrake = 4,
    //急加速
    RecordType_HeavyStart = 5,
    //急左转
    RecordType_HeavyTurnLeft = 6,
    //急右转
    RecordType_HeavyTurnRight = 7,
    //超速
    RecordType_CrazySpeed = 8,
    //打电话
    RecordType_CallPhone = 9,
    //接电话
    RecordType_AnswerPhone = 10,
    //发短信
    RecordType_SendMessage = 11,
    //读短信
    RecordType_ReadMessage = 12,
    //使用手机
    RecordType_UsePhone = 13,
    //疲劳驾驶
    RecordType_FatigueDriving = 14,
    //转速不匹配
    RecordType_SpeedNotMatch = 15,
    //高转速
    RecordType_HighRotationNo = 16,
    //常怠速
    RecordType_IdelNo = 17,
    //低电量
    RecordType_LowPowner = 18,
    //变道
    RecordType_ChangeRoad = 19,
} RecordType;

//电话类型
typedef enum {
    CallState_Unknow = 0,
    //呼出
    CallState_CallOut = 1,
    //呼入
    CallState_CallIn = 2,
    //连通
    CallState_Connected = 3,
    //断连
    CallState_Disconnected = 4,
    //呼入接听
    CallState_CallInDone = 5,
    //呼出接听
    CallState_CallOutDone = 6,
} CallState;

//手机附件连接状态
typedef enum {
    //未知
    ConnectedState_Unknow = 0,
    //没有
    ConnectedState_None = 1,
    //扬声器
    ConnectedState_Loudspeeker = 2,
    //听筒
    ConnectedState_Headphones = 3,
    //有线耳机
    ConnectedState_Wiredheadset = 4,
    //蓝牙耳机
    ConnectedState_BluetoothHFP = 5,
} ConnectedState;

//道路类型
typedef enum {
    //高速
    RoadType_HighWayRoad = 0,
    //快速路
    RoadType_FastRoad = 1,
    //主干道
    RoadType_PrimaryRoad = 2,
    //次干道
    RoadType_SecondaryRoad = 3,
    //支路
    RoadType_BranchRoad = 4,
} RoadType;

typedef enum {
    EventType_Powner   = 0,     // 电量事件
    EventType_Wifi     = 1,     // 网络事件
    EventType_Memory   = 2,     // 内存事件
    EventType_Region   = 3,     // iBeacon事件
} EventType;


typedef enum {
    EventValue_Off     = 0,     // 关闭事件
    EventValue_On      = 1,     // 开启事件
} EventValue;


//异常类型
typedef enum {
    AbnormalType_HeavyBrake = 1,
    AbnormalType_HeavyStart = 2,
    AbnormalType_HeavyTurnLeft = 3,
    AbnormalType_HeavyTurnRight = 4,
    AbnormalType_CrazySpeed = 5,
    AbnormalType_CallPhone = 6,
    AbnormalType_AnswerPhone = 7,
    AbnormalType_SendMessage = 8,
    AbnormalType_ReadMessage = 9,
    AbnormalType_UsePhone = 10,
    //疲劳驾驶
    AbnormalType_FatigueDriving = 11,
    //转速不匹配
    AbnormalType_SpeedNotMatch = 12,
    //高转速
    AbnormalType_HighRotationNo = 13,
    //常怠速
    AbnormalType_IdelNo = 14,
} AbnormalType;

//记步类型
typedef enum {
    PedometerType_Walk = 1,
    PedometerType_Drive = 2,
    PedometerType_Stop = 3,
} PedometerType;

//路途类型
typedef enum {
    RoadwayType_Walk = 1,
    RoadwayType_Drive = 2,
    RoadwayType_Stop = 3,
} RoadwayType;



#pragma mark - Macros

/***************************固定阀值******************************/
#define ONEPAGECOUNT                  10            //一页显示的数据条数
#define STOP_RECORD_TIME              600           //10分钟内没有移动则停止记录
#define ONESTEP_ANALYZE_ARRAYCOUNT    300           //一次分析500条数据
#define ABNORMAL_ACCELERATION_VALUE   0.7           //异常加速度阀值
#define HORIZONTALACCURACY            200           //水平面允许的误差范围
#define WALKING_SPEED                 6             //步行的速度上线
#define STOP_SPEED                    1             //考虑卫星误差后的静止速度
#define ORIENTATIONCHANGE_VALUE       20            //地图标记的方向转变的阀值
#define PEDOMETERTYPEWALK_VALUE       6             //判断步行阀值


#define MAPPOINT_HIGHTSPEED           27.8          //地图标记的快速阀值
#define TRAVELRECORD_INTERVAL_10      10            //同型取点间隔
#define TRAVELRECORD_INTERVAL_5       5             //异常取点间隔
#define MAXMAPPOINT                   2000          //详情页地图上能容纳点的个数

#define REQUEST_TIMEOU        @"timeOut"

#define needMergetime 5
#define carDrivingTime 5

#define WEAK_SELF                   typeof(self) __weak weakSelf = self;
#define APP_DELEGATE                (AppDelegate *)[[UIApplication sharedApplication] delegate]
#define TABBAR_HEIGHT 49             //自定义UITabBar的高度
#define STATEBAR_HEIGHT 20           //状态栏高度
#define TABBAR_HEIGHT 49             //自定义UITabBar的高度
#define TABBAR_TAP_BUTTON_WIDTH 32   //TabBar按钮的宽度
//#define TABART_BUTTON_WIDTH 120
#define IPHONE_WIDTH 320   //设备像素宽度
#define IPHONE_HEIGHT 480  //设备高度
#define IPHONE5_HEIGHT 568 //iPhone5设备的高度
#define NAVIGATIONBAR_HEIGHT 44      // 导航栏的高度
#define DSLOWPOWER  20              //低电量

/***************************各种宏******************************/
#define DS_SERVER_FIRST_BOOL_KEY                        @"DS_SERVER_FIRST_BOOL_KEY"//提示过了用户打开运动侦测
#define DS_SERVER_UPDATE_DATE                           @"DS_SERVER_UPDATE_DATE"//上次提示的时间


#endif /* DSDefines_h */
