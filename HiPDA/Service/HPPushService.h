//
//  Created by Jichao Wu on 15/3/17.
//  Copyright (c) 2015年 Jichao Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPPushService : NSObject

+ (void)doRegister;

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
                                                   error:(NSError *)error;

+ (void)didRecieveRemoteNotification:(NSDictionary *)userInfo fromLaunching:(BOOL)fromLaunching;

+ (NSString *)currDeviceToken;

@end
