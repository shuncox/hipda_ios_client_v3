//
//  HPBlockThreadService.m
//  HiPDA
//
//  Created by Jiangfan on 2019/10/14.
//  Copyright © 2019 wujichao. All rights reserved.
//

#import "HPBlockThreadService.h"
#import "HPThread.h"
#import "HPJSON.h"
#import <Mantle/Mantle.h>
#import <BlocksKit/BlocksKit.h>
#import "HPBlockThread.h"

@interface HPBlockThreadConfig : MTLModel <MTLJSONSerializing>
@property (nonatomic, strong) NSArray<HPBlockThread *> *list;
@end

@implementation HPBlockThreadConfig
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{};
}
+ (NSValueTransformer *)listJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:HPBlockThread.class];
}
@end

@interface HPBlockThreadService()

@property (nonatomic, strong) NSMutableArray<HPBlockThread *> *list;
@property (nonatomic, strong) NSMutableSet *hashTable;

@end

@implementation HPBlockThreadService

+ (HPBlockThreadService *)shared
{
    static dispatch_once_t once;
    static HPBlockThreadService *singleton;
    dispatch_once(&once, ^ { singleton = [[HPBlockThreadService alloc] init]; });
    return singleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self rebuildWithList:[self.class getSavedList]];
    }
    return self;
}

- (void)rebuildWithList:(NSArray *)list
{
    self.list = [NSMutableArray arrayWithArray:list];
    self.hashTable = [NSMutableSet setWithArray:[self.list bk_map:^id(HPBlockThread *obj) {
        return @(obj.tid);
    }]];
}

- (void)updateList:(void(^)())block
{
    // update local data
    block();
    [self saveAll];
}

#pragma mark -
- (BOOL)isThreadInBlockList:(int)tid
{
    return [self.hashTable containsObject:@(tid)];
}

#pragma mark - add & remove thread

- (void)addThread:(HPThread *)thread
{
    NSParameterAssert(thread);
    return [self addThreads:@[thread]];
}

- (void)removeThread:(int)tid
{
    NSParameterAssert(tid > 0);
    return [self removeThreads:@[@(tid)]];
}

- (void)addThreads:(NSArray *)threads
{
    [self updateList:^{
        for (HPThread *thread in threads) {
            NSParameterAssert(thread.tid > 0);
            
            if ([self.hashTable containsObject:@(thread.tid)]) {
                continue;
            }
            
            HPBlockThread *t = [HPBlockThread new];
            t.fid = thread.fid;
            t.tid = thread.tid;
            t.title = thread.title;
            
            [self.list addObject:t];
            [self.hashTable addObject:@(thread.tid)];
        }
    }];
}

- (void)removeThreads:(NSArray *)tids
{
    [self updateList:^{
        for (NSNumber *tid in tids) {
            NSParameterAssert(tid);
        
            if (![self.hashTable containsObject:tid]) {
                continue;
            }
            for (int i = 0; i < self.list.count; i++) {
                if (self.list[i].tid == tid.integerValue) {
                    [self.list removeObjectAtIndex:i];
                    break;
                }
            }
            [self.hashTable removeObject:tid];
        }
    }];
}

#pragma mark -
- (NSArray *)blockList
{
    return self.list;
}

#pragma mark - persistence

- (void)saveAll
{
    [self.class saveList:[self.list copy]];
}

+ (NSArray *)getSavedList
{
    NSString *json = [NSStandardUserDefaults objectForKey:@"HPSavedThreadList"];
    HPBlockThreadConfig *config = (HPBlockThreadConfig *)[HPJSON mtl_fromJSON:json class:HPBlockThreadConfig.class];
    return config ? config.list : @[];
}

+ (void)saveList:(NSArray *)list
{
    HPBlockThreadConfig *config = [HPBlockThreadConfig new];
    config.list = list;
    NSString *json = [HPJSON mtl_toJSON:config];
    [NSStandardUserDefaults saveObject:json forKey:@"HPSavedThreadList"];
}

@end
