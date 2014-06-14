//
//  HPMessage.h
//  HiPDA
//
//  Created by wujichao on 13-11-24.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    HPMessageRangeLatest = 3,
    HPMessageRangeCurrentWeek,
    HPMessageRangeAll
} HPMessageRange;

@interface HPMessage : NSObject

@property (nonatomic, strong) NSArray *message_list;

+ (HPMessage *)sharedMessage;
- (void)cacheMyMessages:(NSArray *)list;


+ (void)sendMessageWithUsername:(NSString *)username
                        message:(NSString *)message
                          block:(void (^)(NSError *error))block;
+ (void)ignoreMessage;

+ (void)loadMessageDetailWithUid:(NSInteger)uid
                       daterange:(HPMessageRange)range
                           block:(void (^)(NSArray *lists, NSError *error))block;

+ (void)loadMessageListWithBlock:(void (^)(NSArray *info, NSError *error))block
                            page:(NSInteger)page;

//+ (void)checkPMWithBlock:(void (^)(int pmCount, NSError *error))block;

+ (void)report:(NSString *)username
       message:(NSString *)message
         block:(void (^)(NSError *error))block;
@end
