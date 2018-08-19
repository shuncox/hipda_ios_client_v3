//
//  HPBackgroundFetchService.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/19.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPBackgroundFetchService : NSObject

+ (instancetype)instance;

- (BOOL)isEnable;

- (void)setupBgFetch;
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end
