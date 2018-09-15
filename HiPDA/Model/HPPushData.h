//
//  HPPushData.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

typedef NS_ENUM(NSUInteger, HPPushType) {
    HPPushTypeMessage = 0,
    HPPushTypeSub = 1,
};

@interface HPPushData : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSDictionary *aps;

@property (nonatomic, assign) HPPushType type;

/*
 * TODO: 待优化, 多种type混用一个model肯定是不对的. 更好的办法还没想出来
 */

/*
 * HPPushTypeMessage
 */
@property (nonatomic, assign) int pm;
@property (nonatomic, assign) int thread;

/*
 * HPPushTypeSub
 */
@property (nonatomic, assign) int tid;

@end
