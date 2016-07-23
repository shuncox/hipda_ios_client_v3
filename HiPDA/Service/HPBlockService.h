//
//  HPBlockService.h
//  HiPDA
//
//  Created by Jiangfan on 16/7/18.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPBlockService : NSObject

+ (HPBlockService *)shared;

- (void)updateWithBlock:(void (^)(NSError *error))completionHandler;

- (BOOL)isUserInBlockList:(NSString *)username;
- (NSArray *)blockList;

- (void)addUser:(NSString *)username;
- (void)removeUser:(NSString *)username;
- (void)addUsers:(NSArray *)users;
- (void)removeUsers:(NSArray *)users;

@end