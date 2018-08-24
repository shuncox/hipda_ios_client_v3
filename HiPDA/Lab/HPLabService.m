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
#import "HPLabGuideViewController.h"
#import "HPAccount.h"

@interface HPLabService()

@property (nonatomic, strong) HPApiLabConfig *config;

@end

@implementation HPLabService

+ (instancetype)instance
{
    static dispatch_once_t once;
    static HPLabService *singleton;
    dispatch_once(&once, ^ { singleton = [[HPLabService alloc] init]; });
    return singleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showGuideIfNeeded)
                                                     name:HPLoadThreadListSuccess
                                                   object:nil];
    }
    return self;
}

#pragma mark - cookiesPermission

- (BOOL)grantUploadCookies
{
    return [[HPSetting sharedSetting] boolForKey:HPSettingLabCookiesPermission];
}

- (void)setGrantUploadCookies:(BOOL)grant
{
    [[HPSetting sharedSetting] saveBool:grant forKey:HPSettingLabCookiesPermission];
}


- (FBLPromise *)checkCookiesPermission
{
    if ([HPLabService instance].grantUploadCookies) {
        return [FBLPromise resolvedWith:@YES];
    }
    
    // 已登录也算授权
    if ([HPLabUserService instance].isLogin) {
        return [FBLPromise resolvedWith:@YES];
    }
   
    return [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock reject) {
        [self getLabConfig]
        .then(^id(HPApiLabConfig *config){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:config.notice delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
            [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex != alertView.cancelButtonIndex) {
                    self.grantUploadCookies = YES;
                    fulfill(@YES);
                } else {
                    fulfill(@NO);
                }
            }];
            return config;
        })
        .catch(^(NSError *error) {
            fulfill(@NO);
        });
    }];
}

#pragma mark - push

- (BOOL)enableMessagePush
{
    return [[HPSetting sharedSetting] boolForKey:HPSettingLabEnablePush];
}

- (void)setEnableMessagePush:(BOOL)enable
{
    [[HPSetting sharedSetting] saveBool:enable forKey:HPSettingLabEnablePush];
}

- (FBLPromise<NSNumber/*BOOL*/ *> *)getPushEnable
{
    return [[HPApi instance] request:@"/message/state" params:nil]
    .then(^id(NSDictionary *data) {
        return data[@"enable"];
    });
}

- (FBLPromise<NSNumber/*BOOL*/ *> *)updatePushEnable:(BOOL)enable;
{
    return [[HPApi instance] request:@"/message/enable"
                              params:@{@"enable": @(enable)}]
    .then(^id(id data) {
        return @(enable);
    });
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

#pragma mark - config
- (FBLPromise<HPApiLabConfig *> *)getLabConfig
{
    if (self.config) {
        return [FBLPromise resolvedWith:self.config];
    }
    
    return [[HPApi instance] request:@"/config/get"
                              params:@{@"key": @"lab_config"}
                         returnClass:HPApiLabConfig.class
                           needLogin:NO]
    .then(^id(HPApiLabConfig *config) {
        self.config = config;
        return config;
    });
}

#pragma mark - guide
- (void)showGuideIfNeeded
{
    if ([HPAccount isAccountForReviewer]) {
        return;
    }
    
    NSString *key = @"ShowLabGuideFlag";
    BOOL didShow = [NSStandardUserDefaults boolForKey:key or:NO];
    if (didShow) {
        return;
    }
    [NSStandardUserDefaults saveBool:YES forKey:key];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"新功能内测邀请" message:@"实时的短消息推送功能, 邀请您内测" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"好的", nil];
    [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [HPLabGuideViewController presentIn:nil];
        }
    }];
}

@end
