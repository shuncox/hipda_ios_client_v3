//
//  HPBlockService.m
//  HiPDA
//
//  Created by Jiangfan on 16/7/18.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "HPBlockService.h"
#import <CloudKit/CloudKit.h>
#import "HPSetting.h"

@interface HPBlockService()

@property (nonatomic, strong) NSMutableArray *list;
@property (nonatomic, strong) NSMutableSet *hashTable;

@end

@implementation HPBlockService

+ (HPBlockService *)shared
{
    static dispatch_once_t once;
    static HPBlockService *singleton;
    dispatch_once(&once, ^ { singleton = [[HPBlockService alloc] init]; });
    return singleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self rebuildWithList:[self.class getSavedList]];
        
        @weakify(self);
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            @strongify(self);
            [self updateWithBlock:^(NSError *error) {
                ;
            }];
        }];
        
        [self migrateOldData];
    }
    return self;
}

- (void)rebuildWithList:(NSArray *)list
{
    self.list = [NSMutableArray arrayWithArray:list];
    self.hashTable = [NSMutableSet setWithArray:self.list];
}

#pragma mark - update
- (void)updateWithBlock:(void (^)(NSError *error))completionHandler
{
    [self.class fetchRecord:^(CKRecord *record, NSError *error) {
        if (!error) {
            [self rebuildWithList:record[@"list"] ?: @[]];
            [self saveAll];
        }
        completionHandler(error);
    }];
}

#pragma mark - cloudKit
+ (void)fetchRecord:(void (^)(CKRecord *record, NSError *error))completionHandler
{
    CKDatabase *privateDB = [[CKContainer defaultContainer] privateCloudDatabase];
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:@"blocklist"]; //id
    
    [privateDB fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
        
        if (error.code == CKErrorUnknownItem) {
            CKRecord *record = [[CKRecord alloc] initWithRecordType:@"BlockList" recordID:recordID];
            [self.class saveRecord:record completionHandler:^(CKRecord *savedRecord, NSError *error) {
                completionHandler(savedRecord, error);
            }];
            return;
        }
        
        // handle errors here
       
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(record, error);
        });
    }];
}

+ (void)saveRecord:(CKRecord *)record
 completionHandler:(void (^)(CKRecord *savedRecord, NSError *error))completionHandler
{
    CKDatabase *privateDB = [[CKContainer defaultContainer] privateCloudDatabase];
    [privateDB saveRecord:record completionHandler:^(CKRecord *savedRecord, NSError *error) {
        // handle errors here
        
        
        // error.code == 9  CKErrorNotAuthenticated need log icloud
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(savedRecord, error);
        });
    }];
}

- (void)updateList:(void(^)())block
{
    // update local data
    block();
    [self saveAll];
    
    // fetch latest data
    [self.class fetchRecord:^(CKRecord *record, NSError *error) {
        if (!error) {
            // rebuild
            [self rebuildWithList:record[@"list"] ?: @[]];
            
            block();
            [self saveAll];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kHPBlockListDidChange object:nil];
            
            // update
            record[@"list"] = self.list;
            [self.class saveRecord:record completionHandler:^(CKRecord *savedRecord, NSError *error) {
                ;
            }];
        }
    }];
}

#pragma mark -
- (BOOL)isUserInBlockList:(NSString *)username
{
    return [self.hashTable containsObject:username];
}

#pragma mark - add & remove user

- (void)addUser:(NSString *)username
{
    NSParameterAssert(username.length);
    return [self addUsers:@[username]];
}

- (void)removeUser:(NSString *)username
{
    NSParameterAssert(username.length);
    return [self removeUsers:@[username]];
}

- (void)addUsers:(NSArray *)users
{
    [self updateList:^{
        for (NSString *username in users) {
            NSParameterAssert(username.length);
            
            if ([self.hashTable containsObject:username]) {
                continue;
            }
            
            [self.list addObject:username];
            [self.hashTable addObject:username];
        }
    }];
}

- (void)removeUsers:(NSArray *)users
{
    [self updateList:^{
        for (NSString *username in users) {
            NSParameterAssert(username.length);
            
            if (![self.hashTable containsObject:username]) {
                continue;
            }
            
            [self.list removeObject:username];
            [self.hashTable removeObject:username];
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
    return [NSStandardUserDefaults objectForKey:@"HPSavedList_V2"];
}

+ (void)saveList:(NSArray *)list
{
    [NSStandardUserDefaults saveObject:list forKey:@"HPSavedList_V2"];
}

#pragma mark - migrate
- (void)migrateOldData
{
    NSArray *list = [Setting objectForKey:HPSettingBlockList];
    if (list.count) {
        [self addUsers:list];
        [Setting saveObject:@[] forKey:HPSettingBlockList];
    }
}

@end