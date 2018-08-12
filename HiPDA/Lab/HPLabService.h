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
@property (nonatomic, assign) BOOL cookiesPermission;
- (FBLPromise<NSNumber/*BOOL*/ *> *)checkCookiesPermission;

// 开启消息推送
@property (nonatomic, assign) BOOL enablePush;
- (FBLPromise<NSNumber/*BOOL*/ *> *)getPushEnable;
- (FBLPromise *)updatePushEnable:(BOOL)enable;

// 开启订阅
@property (nonatomic, assign) BOOL enableSubscribe;

@end
