//
//  HPPushData.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPPushData : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSDictionary *aps;
@property (nonatomic, assign) int pm;
@property (nonatomic, assign) int thread;

@end
