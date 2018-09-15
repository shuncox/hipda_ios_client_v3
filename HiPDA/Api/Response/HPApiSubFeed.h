//
//  HPApiSubFeed.h
//  HiPDA
//
//  Created by Jiangfan on 2018/9/15.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "HPApiThread.h"
#import "HPApiSubByUser.h"
#import "HPApiSubByKeyword.h"

@interface HPApiSubFeed : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) HPApiThread *threadInfo;
@property (nonatomic, strong) HPApiSubByUser *subByUser;
@property (nonatomic, strong) HPApiSubByKeyword *subByKeyword;

@end
