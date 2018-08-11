//
//  Created by Jichao Wu on 15/3/17.
//  Copyright (c) 2015年 Jichao Wu. All rights reserved.
//

#import "HPPushService.h"
#import "HPApi.h"

static NSString * const NOTIFICATION_DEVICE_TOKEN = @"NOTIFICATION_DEVICE_TOKEN";

@implementation HPPushService

+ (void)doRegister {
    [HPPushService registerForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                   categories:nil];
}

+ (void)registerForTypes:(UIRemoteNotificationType)types
              categories:(NSSet *)categories
{
    UIApplication *app = [UIApplication sharedApplication];
    if (IOS8_OR_LATER) {
        [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationType)types
                                                                                categories:categories]];

        [app registerForRemoteNotifications];
    } else {
        [app registerForRemoteNotificationTypes:types];
    }
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
                                                   error:(NSError *)error
{
    NSLog(@"push token: %@, error: %@", deviceToken, error);
    if (error) {
        return;
    }
    
#ifdef DEBUG
    int env = 1;
#else
    int env = 0;
#endif
    NSString *key = [NSString stringWithFormat:@"%@_%@", NOTIFICATION_DEVICE_TOKEN, @(env)];
    
    NSString *tokenString = [[[[NSString stringWithFormat:@"%@", deviceToken] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *oldDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:key];
   
    if (oldDeviceToken && [tokenString isEqualToString:oldDeviceToken]) {
        DDLogInfo(@"token没有变");
        return;
    }
    
    [[[[HPApi instance] request:@"/device_token/update"
                         params:@{@"currToken": tokenString,
                                  @"prevToken": oldDeviceToken ?: @"",
                                  @"env": @(env)}]
      then:^id(id data) {
          [[NSUserDefaults standardUserDefaults] setObject:tokenString forKey:key];
          [[NSUserDefaults standardUserDefaults] synchronize];
          return nil;
      }] catch:^(NSError *error) {
          DDLogError(@"token上传失败 %@", error);
      }];
}

+ (void)didRecieveRemoteNotification:(NSDictionary *)userInfo
                       fromLaunching:(BOOL)fromLaunching {
    
    /*{
        "aps": {
            "alert": "【黄晓明躲baby身..",
            "badge": null,
            "sound": null
        },
        "mt": 5,
        "rid": "notice_132401"
    }*/
    long type = [[userInfo objectForKey:@"mt"] longValue];
    NSString *refIdentifier = [userInfo objectForKey:@"rid"];
    
    NSString *alertBody = nil;
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    if (aps && [aps isKindOfClass:NSDictionary.class]) {
        alertBody = [userInfo objectForKey:@"alert"];
    }
    
    if (!fromLaunching) {
        return;
    }
}

@end
