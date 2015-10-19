//
//  HPBlockService.h
//  HiPDA
//
//  Created by Jichao Wu on 15/10/16.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>

@interface HPAVBlockList : AVObject<AVSubclassing>

@property (nonatomic, strong) AVUser *user; //所属的user
@property (nonatomic, strong) NSArray *changeLogs; //保存changelog
@property (nonatomic, readonly, strong) NSArray *list; //由 changelog 生成 blockList
@property (nonatomic, readonly, strong) NSDate *lastModifiedAt; //最后生成的时间

@end

@interface HPAVBlockUser : AVObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, assign) long long uid;
@property (nonatomic, strong) NSArray *tags;

@end

@interface HPBlockService : NSObject

@property (nonatomic, readonly, strong) NSDictionary *hashTable;

+ (HPBlockService *)shared;


- (void)updateWithBlock:(AVBooleanResultBlock)block;


- (void)addUser:(HPAVBlockUser *)user;
- (void)removeUser:(HPAVBlockUser *)user;
- (void)addUsers:(NSArray *)users;
- (void)removeUsers:(NSArray *)users;


- (void)getPopularUsersWithBlock:(void(^)(NSArray *list, NSError *error))block;

@end
