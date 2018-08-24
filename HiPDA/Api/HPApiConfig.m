//
//  HPApiConfig.m
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPApiConfig.h"
#import "HPSetting.h"

//static NSString * const DEV_URL = @"http://192.168.2.223:8080/api";
static NSString * const DEV_URL = @"http://172.17.53.5:8080/api";
static NSString * const ONLINE_URL = @"https://apocalypse.jichaowu.com/api";

@implementation HPApiConfig

+ (instancetype)config
{
    static dispatch_once_t once;
    static HPApiConfig *singleton;
    dispatch_once(&once, ^ { singleton = [[HPApiConfig alloc] init]; });
    return singleton;
}

- (id)init
{
    self = [super init];
    if (self) {
#ifdef DEBUG
        self.online = NO;
#else
        self.online = YES;
#endif
    }
    return self;
}

- (BOOL)online
{
    return [self.baseUrl isEqualToString:ONLINE_URL];
}

- (void)setOnline:(BOOL)online
{
    self.baseUrl = online ? ONLINE_URL : DEV_URL;
    [Setting saveBool:online forKey:HPSettingApiEnv];
}

@end
