//
//  Created by Jichao Wu on 15/3/17.
//  Copyright (c) 2015年 Jichao Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PromisesObjC/FBLPromises.h>

@interface HPPushService : NSObject

typedef NS_ENUM(NSInteger, HPAuthorizationStatus) {
    /// Permission status undetermined.
    HPAuthorizationStatusUnDetermined,
    /// Permission denied.
    HPAuthorizationStatusDenied,
    /// Permission authorized.
    HPAuthorizationStatusAuthorized,
};

+ (void)doRegister;

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
                                                   error:(NSError *)error;

+ (void)didRecieveRemoteNotification:(NSDictionary *)userInfo fromLaunching:(BOOL)fromLaunching;

+ (NSString *)currDeviceToken;

+ (FBLPromise<NSNumber/*HPAuthorizationStatus*/ *> *)checkPushPermission;

+ (BOOL)isEnabledRemoteNotification;

@end
