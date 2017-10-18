//
//  AppDelegate.m
//  DriveAndSportRecord
//
//  Created by Tristan on 16/8/4.
//  Copyright © 2016年 Tristan. All rights reserved.
//

#import "AppDelegate.h"
#import "DSDriveAndSportRecord.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    _logServer = [[ECLogServer alloc] init];
    //开启日志服务
    [_logServer open];
    [_logServer deleteOldRecord];
    [_logServer insertDetailTableWithInterface:NSStringFromClass([self class])
                                          type:type_info
                                          text:@"应用启动"];
    
    _globals = [DSGlobals sharedGlobals];
    _record = [DSDriveAndSportRecord sharedRecord];
    
    [_globals setUserId:112233];
    [[_globals backgroundTask] startAllServer];
    
    ViewController *vc = [[ViewController alloc] init];
    self.window.rootViewController = vc;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [_logServer insertDetailTableWithInterface:NSStringFromClass([self class])
                                          type:type_info
                                          text:@"app进后台"];
    _globals.backgroundTask.locationManager.pausesLocationUpdatesAutomatically = NO;
//    [_globals.backgroundTask.locationManager startMonitoringSignificantLocationChanges];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
//    [_globals.backgroundTask.locationManager stopMonitoringSignificantLocationChanges];
    [_globals didBecomeActive];

}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)showInfoInBottomWithText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    
    // Set the text mode to show only text.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:3.f];
}

@end
