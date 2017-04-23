//
//  HPCache.m
//  HiPDA
//
//  Created by wujichao on 13-11-15.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPCache.h"
#import "HPThread.h"
#import "HPNewPost.h"
#import "EGOCache.h"
#import "HPSetting.h"
#import "HPThread.h"

#define DEBUG_CACHE 0

@implementation HPCache

+ (HPCache *)sharedCache {
    static HPCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[HPCache alloc] init];
    
        sharedCache.history = [[NSMutableArray alloc] initWithArray:(NSArray *)[[EGOCache globalCache] objectForKey:kHPHistoryListCacheKey]];
    });
    
    return sharedCache;
}

- (BOOL)isReadThread:(NSInteger)tid pid:(NSInteger)pid {
    
    NSString *key = [NSString stringWithFormat:@"read_notice_%ld_%ld", tid, pid];
    
    if ([[EGOCache globalCache] hasCacheForKey:key]) {
        return YES;
    }
    
    return NO;
}
- (void)readThread:(NSInteger)tid pid:(NSInteger)pid {
    
    NSString *key = [NSString stringWithFormat:@"read_notice_%ld_%ld", tid, pid];
    
    if (DEBUG_CACHE) NSLog(@"readNoticeThread %@", key);
    
    // 864000 10days
    [[EGOCache globalCache] setObject:@YES forKey:key withTimeoutInterval:864000];
}

//
- (BOOL)isReadThread:(NSInteger)tid {
    
    NSString *key = [NSString stringWithFormat:@"read_%ld", tid];
    
    if ([[EGOCache globalCache] hasCacheForKey:key]) {
        return YES;
    }
    
    return NO;
}
- (void)readThreadWithTid:(NSInteger)tid {
    
    NSString *key = [NSString stringWithFormat:@"read_%ld", tid];
    
    if (DEBUG_CACHE) NSLog(@"readThread %@", key);
    
    // 864000 10days
    [[EGOCache globalCache] setObject:@YES forKey:key withTimeoutInterval:864000];
}

- (void)readThread:(HPThread *)thread {
    
    [self readThreadWithTid:thread.tid];
    
    //
    __block NSInteger i = -1;
    [self.history enumerateObjectsUsingBlock:^(HPThread *t, NSUInteger idx, BOOL *stop) {
        //NSLog(@"%d %@ %@",i, thread ,t);
        if (t.tid == thread.tid) {
            i = idx;
            *stop = YES;
        }
    }];
    if (i >= 0) [self.history removeObjectAtIndex:i];
    
    //
    if (self.history.count > 50) {
        [self.history removeLastObject];
    }
    
    //
    [self.history insertObject:thread atIndex:0];
    [[EGOCache globalCache] setObject:self.history forKey:kHPHistoryListCacheKey withTimeoutInterval:864000];
}

- (NSArray *)histotyList {
    
    return self.history;
}

- (void)clearHistoty {
    [self.history removeAllObjects];
    [[EGOCache globalCache] setObject:self.history forKey:kHPHistoryListCacheKey withTimeoutInterval:864000];
}

- (void)removeHistotyAtIndex:(NSInteger)index {
    [self.history removeObjectAtIndex:index];
    [[EGOCache globalCache] setObject:self.history forKey:kHPHistoryListCacheKey withTimeoutInterval:864000];
}

@end
