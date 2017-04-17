//
//  HPJSMessage.m
//  HiPDA
//
//  Created by Jiangfan on 2017/4/17.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPJSMessage.h"

@implementation HPJSMessage

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"method": @"method",
        @"object": @"object"
    };
}

@end
