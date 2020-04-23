//
//  HPCrashReport.m
//  HiPDA
//
//  Created by Jiangfan on 2017/3/5.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPCrashReport.h"
#import "HPAccount.h"
#import <AppCenter/MSAppCenter.h>
#import <AppCenterAnalytics/AppCenterAnalytics.h>
#import <AppCenterCrashes/AppCenterCrashes.h>

void HPCrashLog(NSString *format, ...)
{
    if ([HPCrashReport isCrashReportEnable]) {
        va_list args;
        va_start(args, format);
        //CLSLogv(format, args);
        va_end(args);
    }
}

static NSString * const CrashReportEnableSettingKey = @"CrashReportEnableSettingKey";

@interface HPCrashReport() <MSCrashesDelegate>
@end

@implementation HPCrashReport

+ (HPCrashReport *)instance
{
    static dispatch_once_t once;
    static HPCrashReport *singleton;
    dispatch_once(&once, ^ { singleton = [[HPCrashReport alloc] init]; });
    return singleton;
}

+ (void)setUp
{
    BOOL bugTrackingEnable = [self.class isCrashReportEnable];
    if (bugTrackingEnable) {
        [MSCrashes setDelegate:[HPCrashReport instance]];
        
        [MSAppCenter start:@"323d891b-35ff-4d6e-9aef-819f38214b32" withServices:@[
          [MSAnalytics class],
          [MSCrashes class],
        ]];
        
        NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
        if (username.length > 0) {
            [MSAppCenter setUserId:username];
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

- (NSArray<MSErrorAttachmentLog *> *)attachmentsWithCrashes:(MSCrashes *)crashes
                                             forErrorReport:(MSErrorReport *)errorReport
{
    NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
    MSErrorAttachmentLog *log = [MSErrorAttachmentLog attachmentWithText:username filename:@"hello.txt"];
    return @[log];
}

@end
