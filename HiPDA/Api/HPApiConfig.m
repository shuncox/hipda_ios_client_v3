//
//  HPApiConfig.m
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPApiConfig.h"

@implementation HPApiConfig

+ (instancetype)config
{
    HPApiConfig *config = [HPApiConfig new];
    
#ifdef DEBUG
    config.baseUrl = @"http://192.168.2.223:8080/api";
#else
    config.baseUrl = nil;
#endif

    return config;
}

@end
