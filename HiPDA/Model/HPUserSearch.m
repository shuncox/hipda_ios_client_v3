//
//  HPUserSearch.m
//  HiPDA
//
//  Created by Jiangfan on 2017/5/16.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPUserSearch.h"
#import "HPDatabase.h"
#import "HPUser.h"

@implementation HPUserSearch

+ (RACSignal *)signalForSearchUserWithKey:(NSString *)key {
    
    static NSOperationQueue *q = nil;
    if (!q) {
        q = [[NSOperationQueue alloc] init];
        [q setMaxConcurrentOperationCount:1];
    }
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSBlockOperation *op = [[NSBlockOperation alloc] init];
        
        [op addExecutionBlock:^{
            
            NSMutableArray *results = [NSMutableArray array];
            [[HPDatabase sharedDb].queue inDatabase:^(FMDatabase *db) {
                
                // 优化排序 http://stackoverflow.com/questions/10070508/sqlite-like-order-by-match-query
                NSString *sql = [NSString stringWithFormat:
                                 @"SELECT *\n"
                                 "FROM user\n"
                                 "WHERE username LIKE '%%%@%%'\n"
                                 "ORDER BY (\n"
                                 "CASE WHEN username = '%@' THEN 1\n"
                                 "WHEN username LIKE '%@%%' THEN 2\n"
                                 "ELSE 3 END\n"
                                 "), username\n"
                                 "LIMIT 1000\n", key, key, key];
                
                FMResultSet *resultSet = [db executeQuery:sql];
                
                while ([resultSet next]) {
                    NSString *username = [resultSet stringForColumnIndex:0];
                    NSString *uid = [resultSet stringForColumnIndex:1];
                    
                    HPUser *user = [HPUser new];
                    user.username = username;
                    user.uid = [uid integerValue];
                    [results addObject:user];
                }
            }];
            
            [subscriber sendNext:[results copy]];
            [subscriber sendCompleted];
        }];
        
        [q addOperation:op];
        
        return nil;
    }];
}

@end
