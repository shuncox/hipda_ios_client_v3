//
//  HPLabUserService.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPLabUser.h"
#import <PromisesObjC/FBLPromises.h>

@interface HPLabUserService : NSObject

+ (instancetype)instance;

@property (nonatomic, readonly, strong) HPLabUser *user;

- (BOOL)isLogin;
- (FBLPromise<HPLabUser *> *)loginIfNeeded;
- (FBLPromise<HPLabUser *> *)login;
- (FBLPromise *)logout;
- (void)debug;

@end
