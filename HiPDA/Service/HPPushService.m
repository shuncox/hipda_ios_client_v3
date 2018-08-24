//
//  Created by Jichao Wu on 15/3/17.
//  Copyright (c) 2015年 Jichao Wu. All rights reserved.
//

#import "HPPushService.h"
#import "HPApi.h"
#import "HPPushData.h"
#import "HPRearViewController.h"
#import "UIAlertView+Blocks.h"

static NSString * const NOTIFICATION_DEVICE_TOKEN = @"NOTIFICATION_DEVICE_TOKEN";

#ifdef DEBUG
static const int PUSH_ENV = 1;
#else
static const int PUSH_ENV = 0;
#endif

@implementation HPPushService

+ (void)doRegister {
    [HPPushService registerForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                   categories:nil];
}

+ (void)registerForTypes:(UIRemoteNotificationType)types
              categories:(NSSet *)categories
{
    UIApplication *app = [UIApplication sharedApplication];
    [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationType)types
                                                                            categories:categories]];

    [app registerForRemoteNotifications];
}

+ (BOOL)isEnabledRemoteNotification
{
    UIUserNotificationType types = [[[UIApplication sharedApplication] currentUserNotificationSettings] types];
    return types != UIUserNotificationTypeNone;
}

+ (FBLPromise<NSNumber/*HPAuthorizationStatus*/ *> *)checkPushPermission
{
    BOOL grant = [HPPushService isEnabledRemoteNotification];
    if (grant) {
        return [FBLPromise resolvedWith:@(HPAuthorizationStatusAuthorized)];
    }
    // 如果问过, 判断是否同意, 返回是否同意
    BOOL didAskForPermission = [NSStandardUserDefaults boolForKey:kHPAskNotificationPermission or:NO];
    if (didAskForPermission) {
        return [FBLPromise resolvedWith:@(HPAuthorizationStatusDenied)];
    }
    
    // 如果没问过, 不搞预先询问了, 直接doRegister, 暂时不太好拿到回调, 直接返回未定, 走下一步
    [HPPushService doRegister];
    return [FBLPromise resolvedWith:@(HPAuthorizationStatusUnDetermined)];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
                                                   error:(NSError *)error
{
    NSLog(@"push token: %@, error: %@", deviceToken, error);
    if (error) {
        return;
    }
    
    NSString *key = [HPPushService buildTokenKey];
    
    NSString *tokenString = [[[[NSString stringWithFormat:@"%@", deviceToken] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *oldDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:key];
   
    if (oldDeviceToken && [tokenString isEqualToString:oldDeviceToken]) {
        DDLogInfo(@"token没有变");
        return;
    }

    [[[[HPApi instance] request:@"/device_token/update"
                         params:@{@"currToken": tokenString,
                                  @"prevToken": oldDeviceToken ?: @"",
                                  @"env": @(PUSH_ENV)}]
      then:^id(id data) {
          [[NSUserDefaults standardUserDefaults] setObject:tokenString forKey:key];
          [[NSUserDefaults standardUserDefaults] synchronize];
          return nil;
      }] catch:^(NSError *error) {
          DDLogError(@"token上传失败 %@", error);
      }];
}

+ (NSString *)currDeviceToken
{
    NSString *key = [HPPushService buildTokenKey];
    NSString *oldDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return oldDeviceToken;
}

+ (NSString *)buildTokenKey
{
    NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
    NSString *key = [NSString stringWithFormat:@"%@_%@_%@", NOTIFICATION_DEVICE_TOKEN, @(PUSH_ENV), username];
    return key;
}

+ (void)didRecieveRemoteNotification:(NSDictionary *)userInfo
                       fromLaunching:(BOOL)fromLaunching {
    
    HPPushData *data = [MTLJSONAdapter modelOfClass:HPPushData.class
                                 fromJSONDictionary:userInfo
                                              error:nil];
    
    NSString *title = data.aps[@"alert"];
    
    // 用户点开推送就清空App角标
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    // App在前台收到推送, 弹窗提示
    if (!fromLaunching) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提醒"
                                                            message:title
                                                           delegate:nil
                                                  cancelButtonTitle:@"忽略"
                                                  otherButtonTitles:@"查看", nil];
        [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [HPPushService routeToTargetViewController:data];
            }
        }];
        return;
    }
    
    [HPPushService routeToTargetViewController:data];
}

+ (void)routeToTargetViewController:(HPPushData *)data {
    HPRearViewController *rearViewController = [HPRearViewController sharedRearVC];
    
    if (data.pm > 0) {
        [rearViewController switchToMessageVC];
    } else if (data.thread > 0) {
        [rearViewController switchToNoticeVC];
    }
}

@end
