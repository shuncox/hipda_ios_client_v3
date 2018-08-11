//
//  HPApiResult.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/9.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPApiResult : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, assign) int code;
@property (nonatomic, strong) NSString *message;

@end
