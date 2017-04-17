//
//  FLWeakProxy.h
//  HiPDA
//
//  Created by Jiangfan on 2017/4/17.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLWeakProxy : NSProxy

+ (instancetype)weakProxyForObject:(id)targetObject;

@end
