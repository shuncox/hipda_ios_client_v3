//
//  HPAccount.h
//  HiPDA
//
//  Created by wujichao on 13-11-11.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^NoticeRetrieveBlock)(UIBackgroundFetchResult result);



@interface HPAccount : NSObject

@property (nonatomic, copy) NoticeRetrieveBlock noticeRetrieveBlock;

+ (HPAccount *)sharedHPAccount;

//
+ (BOOL)isSetAccount;

// 是否是审核用的账号
+ (BOOL)isAccountForReviewer;

// login & out
- (void)loginWithBlock:(void (^)(BOOL isLogin, NSError *error))block;
- (void)logout;


//fake register
- (void)registerWithBlock:(void (^)(BOOL isLogin, NSError *error))block;

- (void)checkMsgAndNoticeFromAnyPage:(NSString *)html;

// bg fetch
- (void)startCheckWithDelay:(NSTimeInterval)delay;
- (NSInteger)badgeNumber;

- (BOOL)checkLocalNotificationPermission;
- (void)askLocalNotificationPermission;

@end
