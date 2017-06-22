//
//  HPCommon.m
//  HiPDA
//
//  Created by wujichao on 13-11-12.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPCommon.h"
#import "HPSetting.h"
#import "HPNavigationController.h"
//#import <SystemConfiguration/CaptiveNetwork.h>
#import "HPSwipeRootViewController.h"

@implementation HPCommon


+ (NSTimeInterval)timeIntervalSince1970WithString:(NSString *)string {
    NSDateFormatter *mmddccyy = [[NSDateFormatter alloc] init];
    mmddccyy.timeStyle = NSDateFormatterNoStyle;
    mmddccyy.dateFormat = @"yyyy/MM/dd";
    
    NSDate *d = [mmddccyy dateFromString:string];
    //NSLog(@"%f", [d timeIntervalSince1970]);
    return [d timeIntervalSince1970];
}

+ (UINavigationController *)NVCWithRootVC:(UIViewController *)rootVC {
    UINavigationController *NVC = [[HPNavigationController alloc] initWithRootViewController:rootVC];
    if (![Setting boolForKey:HPSettingNightMode]) {
        NVC.navigationBar.barStyle = UIBarStyleDefault;
    } else {
        NVC.navigationBar.barStyle = UIBarStyleBlack;
    }
    return NVC;
}

+ (UINavigationController *)swipeableNVCWithRootVC:(UIViewController *)rootVC {
    UINavigationController *NVC = [[HPNavigationController alloc] initWithRootViewController:rootVC];
    if (![Setting boolForKey:HPSettingNightMode]) {
        NVC.navigationBar.barStyle = UIBarStyleDefault;
    } else {
        NVC.navigationBar.barStyle = UIBarStyleBlack;
    }
    
    if (IOS8_OR_LATER) {
        UIViewController *root = [HPSwipeRootViewController new];
        NVC.viewControllers = @[root, rootVC];
        NVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    
    return NVC;
}

inline Class PostViewControllerClass()
{
    BOOL enableWKWebview = [UMOnlineConfig getBoolConfigWithKey:HPOnlineWKWebviewEnable defaultYES:NO];
    
    // 线上配置允许, 再看用户配置
    if (enableWKWebview) {
        enableWKWebview = [Setting boolForKey:HPSettingEnableWKWebview];
    }
    
    if (!IOS8_OR_LATER) {
        enableWKWebview = NO;
    }
    
    Class clazz = enableWKWebview ?
        NSClassFromString(@"HPPostViewController") :
        NSClassFromString(@"HPReadViewController");
    return clazz;
}

@end
