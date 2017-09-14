//
//  AppDelegate.h
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/4.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSDriveAndSportRecord.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) ECLogServer *logServer;

@property (nonatomic, strong) DSGlobals *globals;

@property (nonatomic, strong) DSDriveAndSportRecord *record;

- (void)showInfoInBottomWithText:(NSString *)text;

@end

