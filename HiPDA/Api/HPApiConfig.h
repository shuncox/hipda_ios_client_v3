//
//  HPApiConfig.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPApiConfig : NSObject

@property (nonatomic, strong) NSString *baseUrl;

+ (instancetype)config;

@end
