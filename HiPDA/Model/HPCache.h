//
//  HPCache.h
//  HiPDA
//
//  Created by wujichao on 13-11-15.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HPThread;
@interface HPCache : NSObject

#define kHPHistoryListCacheKey @"kHPHistoryListCacheKey"

@property (nonatomic, strong) NSMutableArray *history;

+ (HPCache *)sharedCache;

// 标记已读
- (BOOL)isReadThread:(NSInteger)tid;
- (void)readThread:(HPThread *)thread;
- (BOOL)isReadThread:(NSInteger)tid pid:(NSInteger)pid;
- (void)readThread:(NSInteger)tid pid:(NSInteger)pid;

// 历史
- (void)clearHistoty;
- (void)removeHistotyAtIndex:(NSInteger)index;

@end
