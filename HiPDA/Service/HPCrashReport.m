//
//  HPCrashReport.m
//  HiPDA
//
//  Created by Jiangfan on 2017/3/5.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPCrashReport.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "HPAccount.h"

void HPCrashLog(NSString *format, ...)
{
    if ([HPCrashReport isCrashReportEnable]) {
        va_list args;
        va_start(args, format);
        CLSLogv(format, args);
        va_end(args);
    } else {
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}

static NSString * const CrashReportEnableSettingKey = @"CrashReportEnableSettingKey";

@implementation HPCrashReport

+ (void)setUp
{
    [MobClick setCrashReportEnabled:NO];
    
    BOOL bugTrackingEnable = [self.class isCrashReportEnable];
    if (bugTrackingEnable) {
        [Fabric with:@[[Crashlytics class]]];
        
        NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
        if (username.length > 0) {
            [[Crashlytics sharedInstance] setUserIdentifier:username];
        }
    }
}

+ (BOOL)isCrashReportEnable
{
    NSNumber *v = [[NSUserDefaults standardUserDefaults] objectForKey:CrashReportEnableSettingKey];
    if (!v) {
        return YES;
    } else {
        return [v boolValue];
    }
}

+ (void)setCrashReportEnable:(BOOL)crashReportEnable
{
    [[NSUserDefaults standardUserDefaults] setBool:crashReportEnable forKey:CrashReportEnableSettingKey];
}

@end
