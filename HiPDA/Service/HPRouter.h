//
//  HPRouter.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/19.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPRouter : NSObject

+ (instancetype)instance;

- (void)checkPasteboard;
- (void)routeTo:(NSDictionary *)path;

@end
