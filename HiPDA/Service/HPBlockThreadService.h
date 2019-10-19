//
//  HPBlockThreadService.h
//  HiPDA
//
//  Created by Jiangfan on 2019/10/14.
//  Copyright © 2019 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPBlockThread.h"
#import "HPThread.h"

@interface HPBlockThreadService : NSObject

+ (HPBlockThreadService *)shared;

- (NSArray<HPBlockThread *> *)blockList;

- (BOOL)isThreadInBlockList:(int)tid;
- (void)addThread:(HPThread *)thread;
- (void)removeThread:(int)tid;

@end
