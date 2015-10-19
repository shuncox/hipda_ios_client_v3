//
//  HPBlockService.m
//  HiPDA
//
//  Created by Jichao Wu on 15/10/16.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "HPBlockService.h"
#import "HPUserService.h"

@implementation HPAVBlockList

@dynamic user;
@dynamic changeLogs;
@dynamic list;
@dynamic lastModifiedAt;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        [class registerSubclass];
    });
}

+ (NSString *)parseClassName {
    return @"BlockList";
}

@end

@implementation HPAVBlockUser

@dynamic username, uid, tags;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        [class registerSubclass];
    });
}

+ (NSString *)parseClassName {
    return @"BlockUser";
}

@end

@interface HPBlockService()

@property (nonatomic, strong) NSMutableArray *changeLogs;
@property (nonatomic, strong) NSMutableArray *list;

@property (nonatomic, strong) NSDictionary *hashTable;

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
        
        _changeLogs = [NSMutableArray arrayWithArray:[self.class getSavedChangeLogs]];
        _list = [NSMutableArray arrayWithArray:[self.class getSavedList]];
        
    }
    return self;
}

#pragma mark - update
- (void)updateWithBlock:(AVBooleanResultBlock)block
{
    if (![[HPUserService shared] isLogin]) {
        block(NO, nil);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *e = nil;
        
        AVUser *user = [[HPUserService shared] currentUser];
        
        NSString *objectId = user[@"BlockListObjectId"];
        
        // new HPAVBlockList
        if (!objectId) {
            HPAVBlockList *b = [HPAVBlockList object];
            
            b.changeLogs = @[];
            b.user = user;
            
            AVACL *acl =[AVACL ACLWithUser:user];
            b.ACL = acl;
            
            [b save:&e];
            if (e) {
                block(NO, e);
                return;
            }
            
            user[@"BlockListObjectId"] = b.objectId;
            [user save:&e];
            if (e) {
                block(NO, e);
                return;
            }
        }
       
        // upload changeLogs
        if (self.changeLogs.count > 0) {
            HPAVBlockList *b = [HPAVBlockList objectWithoutDataWithObjectId:objectId];
            [b addObjectsFromArray:[self.changeLogs copy] forKey:@keypath(b.changeLogs)];
            [b save:&e];
            if (e) {
                block(NO, e);
                return;
            }
            
            [self.changeLogs removeAllObjects];
            [self.class saveChangeLogs:self.changeLogs];
        }
        
        // get new block list
        NSDictionary *r = [AVCloud callFunction:@"getBlockList"
                                 withParameters:@{@"lastModifiedTime": @([self.class getLastModifiedTime]),
                                                  @"v":@"1.0",
                                                  @"p":@"iOS"}
                                          error:&e];
        if (e) {
            block(NO, e);
            return;
        }
        
        if ([r[@"isChange"] boolValue] == NO) {
            block(YES, nil);
            return;
        }
        
        self.list = [NSMutableArray arrayWithArray:r[@"list"]];
        [self.class saveList:self.list];
        [self.class saveLastModifiedTime:[r[@"lastModifiedTime"] doubleValue]];
        
        [self updateHashTable];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(YES, nil);
        });
    });
}

#pragma mark - add & remove user

- (void)addUser:(HPAVBlockUser *)user
{
    NSParameterAssert(user);
    return [self addUsers:@[user]];
}

- (void)removeUser:(HPAVBlockUser *)user
{
    NSParameterAssert(user);
    return [self removeUsers:@[user]];
}

- (void)addUsers:(NSArray *)users
{
    for (HPAVBlockUser *user in users) {
        
        if ([self.hashTable objectForKey:user.username]) {
            continue;
        }
        
        [self.list addObject:@{@"username": user.username,
                               @"uid": @(user.uid),
                               @"tags": user.tags}];
         
        NSDictionary *log = @{@"username": user.username,
                              @"uid": @(user.uid),
                              @"tags": user.tags,
                              @"type": @"add",
                              @"timeStamp": @([[NSDate date] timeIntervalSince1970])
                              };
        
        [self.changeLogs addObject:log];
    }
    [self updateHashTable];
    [self saveAll];
}

- (void)removeUsers:(NSArray *)users
{
    for (HPAVBlockUser *user in users) {
        
        if (![self.hashTable objectForKey:user.username]) {
            continue;
        }
        
        for (NSDictionary *d in self.list) {
            if ([d[@"username"] isEqualToString:user.username]) {
                [self.list removeObject:d];
                break;
            }
        }
        
        NSDictionary *log = @{@"username": user.username,
                              @"uid": @(user.uid),
                              @"type": @"remove",
                              @"timeStamp": @([[NSDate date] timeIntervalSince1970])
                              };
        
        [self.changeLogs addObject:log];
    }
    [self updateHashTable];
    [self saveAll];
}

#pragma mark - blockList -> Dict

- (NSDictionary *)hashTable
{
    if (_hashTable) return _hashTable;
    
    [self updateHashTable];
    
    return _hashTable;
}

- (void)updateHashTable
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    for (NSDictionary *user in self.list) {
        [d setObject:user forKey:user[@"username"]];
    }
    self.hashTable = [d copy];
}

#pragma mark - popular users
- (void)getPopularUsersWithBlock:(void(^)(NSArray *list, NSError *error))block
{
    ;
}

#pragma mark - persistence

- (void)saveAll
{
    [self.class saveChangeLogs:[self.changeLogs copy]];
    [self.class saveList:[self.list copy]];
}

+ (NSArray *)getSavedChangeLogs
{
    return [NSStandardUserDefaults objectForKey:@"HPSavedChangeLogs_V2"];
}

+ (void)saveChangeLogs:(NSArray *)changeLogs
{
    [NSStandardUserDefaults saveObject:changeLogs forKey:@"HPSavedChangeLogs_V2"];
}

+ (NSArray *)getSavedList
{
    return [NSStandardUserDefaults objectForKey:@"HPSavedList_V2"];
}

+ (void)saveList:(NSArray *)list
{
    [NSStandardUserDefaults saveObject:list forKey:@"HPSavedList_V2"];
}

+ (NSTimeInterval)getLastModifiedTime
{
    return [[NSStandardUserDefaults objectForKey:@"HPLastModifiedTime_V2"] doubleValue];
}

+ (void)saveLastModifiedTime:(double)timeStamp
{
    [NSStandardUserDefaults saveObject:@(timeStamp) forKey:@"HPLastModifiedTime_V2"];
}
@end
