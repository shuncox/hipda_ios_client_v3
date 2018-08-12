//
//  HPLabService.m
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPLabService.h"
#import "HPSetting.h"
#import "HPApi.h"
#import "UIAlertView+Blocks.h"
#import "HPLabUserService.h"

@implementation HPLabService

+ (instancetype)instance
{
    static dispatch_once_t once;
    static HPLabService *singleton;
    dispatch_once(&once, ^ { singleton = [[HPLabService alloc] init]; });
    return singleton;
}

#pragma mark - cookiesPermission

- (BOOL)cookiesPermission
{
    return [[HPSetting sharedSetting] boolForKey:HPSettingLabCookiesPermission];
}

- (void)setCookiesPermission:(BOOL)grant
{
    [[HPSetting sharedSetting] saveBool:grant forKey:HPSettingLabCookiesPermission];
}


- (FBLPromise *)checkCookiesPermission
{
    if ([HPLabService instance].cookiesPermission) {
        return [FBLPromise resolvedWith:@YES];
    }
    
    // 已登录也算授权
    if ([HPLabUserService instance].isLogin) {
        return [FBLPromise resolvedWith:@YES];
    }
   
    return [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock reject) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"确认上传cookies" message:@"blabla..." delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
        [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                self.cookiesPermission = YES;
                fulfill(@YES);
            } else {
                fulfill(@NO);
            }
        }];
    }];
}

#pragma mark - push

- (BOOL)enablePush
{
    return [[HPSetting sharedSetting] boolForKey:HPSettingLabEnablePush];
}

- (void)setEnablePush:(BOOL)enable
{
    [[HPSetting sharedSetting] saveBool:enable forKey:HPSettingLabEnablePush];
}


- (FBLPromise *)getPushEnable
{
    return [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock reject) {
        [[[[HPApi instance] request:@"/message/state"
                             params:nil]
          then:^id(NSDictionary *data) {
              fulfill(data[@"enable"]);
              return nil;
          }] catch:^(NSError *error) {
              reject(error);
          }];
    }];
}

- (FBLPromise *)updatePushEnable:(BOOL)enable
{
    return [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock reject) {
        [[[[HPApi instance] request:@"/message/enable"
                             params:@{@"enable": @(enable)}]
          then:^id(id data) {
              fulfill(data);
              return nil;
          }] catch:^(NSError *error) {
              reject(error);
          }];
    }];
}

#pragma mark - subscribe

- (BOOL)enableSubscribe
{
    return [[HPSetting sharedSetting] boolForKey:HPSettingLabEnableSubscribe];
}

- (void)setEnableSubscribe:(BOOL)enable
{
    [[HPSetting sharedSetting] saveBool:enable forKey:HPSettingLabEnableSubscribe];
}

@end
