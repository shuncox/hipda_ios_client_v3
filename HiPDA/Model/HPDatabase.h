//
//  HPDatabase.h
//  HiPDA
//
//  Created by wujichao on 14-2-23.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>

@interface HPDatabase : NSObject

@property (nonatomic, readonly, strong) FMDatabaseQueue *queue;

+ (HPDatabase *)sharedDb;
+ (BOOL)prepareDb;




/*########################*/

+ (void)loadProfilePageWithUid:(NSInteger)uid
                         block:(void (^)(NSString *html, NSError *error))block;



- (void)test;
- (void)stop;
- (void)start;

@end
