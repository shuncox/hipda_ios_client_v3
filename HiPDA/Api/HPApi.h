//
//  HPApi.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/6.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PromisesObjC/FBLPromises.h>
#import "HPApiPage.h"

@interface HPApi : NSObject

+ (instancetype)instance;

- (FBLPromise *)request:(NSString *)api
                 params:(NSDictionary *)params;

- (FBLPromise *)request:(NSString *)api
                 params:(NSDictionary *)params
            returnClass:(Class)returnClass;

- (FBLPromise<HPApiPage *> *)request:(NSString *)api
                              params:(NSDictionary *)params
                       modelsOfClass:(Class)modelsOfClass;

- (FBLPromise *)request:(NSString *)api
                 params:(NSDictionary *)params
            returnClass:(Class)returnClass
              needLogin:(BOOL)needLogin;

@end
