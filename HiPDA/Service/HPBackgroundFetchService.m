//
//  HPBackgroundFetchService.m
//  HiPDA
//
//  Created by Jiangfan on 2018/8/19.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPBackgroundFetchService.h"
#import "HPLabService.h"
#import "HPSetting.h"
#import "HPAccount.h"
#import "UIAlertView+Blocks.h"

@implementation HPBackgroundFetchService

+ (instancetype)instance
{
    static dispatch_once_t once;
    static HPBackgroundFetchService *singleton;
    dispatch_once(&once, ^ { singleton = [[HPBackgroundFetchService alloc] init]; });
    return singleton;
}

- (BOOL)isEnable
{
    if ([HPLabService instance].enableMessagePush) {
        return NO;
    }
    
    return [Setting boolForKey:HPSettingBgFetchNotice];
}


- (void)setupBgFetch {
    if (self.isEnable) {
        NSInteger interval = [Setting integerForKey:HPBgFetchInterval];
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:interval * 60.f];
        
        NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
        BOOL haveAsk = [NSStandardUserDefaults boolForKey:kHPAskNotificationPermission or:NO];
        BOOL haveLogin = [HPAccount isSetAccount] && ![username isEqualToString:@"wujichao"];
        
        if (!haveAsk && haveLogin && IOS8_OR_LATER) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"请求后台伪推送权限" message:@"Hi, 俺利用了iOS7+的后台应用程序刷新来实现新消息的推送，不是很及时，但有总比没有好。\n但是，发送本地推送需要您的授权，若您需要这个功能请点击授权" delegate:nil cancelButtonTitle:@"不" otherButtonTitles:@"授权", nil];
            [alert showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex != alertView.cancelButtonIndex) {
                    [[HPAccount sharedHPAccount] askLocalNotificationPermission];
                } else {
                    [Setting saveBool:NO forKey:HPSettingBgFetchNotice];
                }
            }];
        }
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if (!self.isEnable) {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    [[HPAccount sharedHPAccount] setNoticeRetrieveBlock:^(UIBackgroundFetchResult result) {
        // log
        //
        NSMutableArray *log = [NSMutableArray arrayWithArray:[NSStandardUserDefaults objectForKey:@"HPBgFetchLog"]];
        
        if (log.count > 233) {
            [log removeLastObject];
        }
        
        NSInteger interval = [Setting integerForKey:HPBgFetchInterval];
        [log insertObject:@{@"interval":@(interval),
                            @"date":[NSDate date],
                            @"result":@(result)} //0 NewData, 1 NoData, 2 Failed
                  atIndex:0];
        [NSStandardUserDefaults saveObject:log forKey:@"HPBgFetchLog"];
        //NSLog(@"%@", log);
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(result);
        });
    }];
    [[HPAccount sharedHPAccount] startCheckWithDelay:0.f];
}


@end
