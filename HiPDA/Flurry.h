//
//  Flurry.h
//  HiPDA
//
//  Created by Jichao Wu on 14-10-13.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Flurry : NSObject

+ (void)logEvent:(NSString *)eventName;

+ (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;

+ (void)setUserID:(NSString *)userID;

+ (void)trackUserIfNeeded;

@end
