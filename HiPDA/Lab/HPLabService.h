//
//  HPLabService.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PromisesObjC/FBLPromises.h>

@interface HPLabService : NSObject

+ (instancetype)instance;

// 授权上传cookies
@property (nonatomic, assign) BOOL grantUploadCookies;
- (FBLPromise<NSNumber/*BOOL*/ *> *)checkCookiesPermission;

// 开启消息推送
@property (nonatomic, assign) BOOL enableMessagePush;
- (FBLPromise<NSNumber/*BOOL*/ *> *)getPushEnable;
- (FBLPromise<NSNumber/*BOOL*/ *> *)updatePushEnable:(BOOL)enable;

// 开启订阅
@property (nonatomic, assign) BOOL enableSubscribe;

@end
