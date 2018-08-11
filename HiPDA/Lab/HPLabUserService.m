//
//  HPLabUserService.m
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPLabUserService.h"
#import "HPApi.h"
#import "NSError+HPError.h"
#import "HPHttpClient.h"

@interface HPLabUserService()

@property (nonatomic, strong) HPLabUser *user;

@end

@implementation HPLabUserService

+ (instancetype)instance
{
    static dispatch_once_t once;
    static HPLabUserService *singleton;
    dispatch_once(&once, ^ { singleton = [[HPLabUserService alloc] init]; });
    return singleton;
}

- (BOOL)isLogin
{
    return !!self.user;
}

- (FBLPromise *)login
{
    return [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock reject) {
        
        // 1. 获取 cdb_auth
        NSString *cdb_auth = nil;
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
        for (NSHTTPCookie *c in cookies) {
            if ([c.domain hasSuffix:@".hi-pda.com"]
                && [c.name isEqualToString:@"cdb_auth"]) {
                cdb_auth = c.value;
                break;
            }
        }
        if (!cdb_auth.length) {
            reject([NSError errorWithErrorCode:-1 errorMsg:@"获取cookies失败"]);
            return;
        }
        
        // 2. 获取UA
        NSString *ua = [[HPHttpClient sharedClient] defaultValueForHeader:@"User-Agent"];
        
        // 3. 获取userId
        NSString *uid = [[NSUserDefaults standardUserDefaults] objectForKey:kHPAccountUID];
        long userId = [uid longLongValue];
        
        [[[[HPApi instance] request:@"/user/login"
                             params:@{@"cdb_auth": cdb_auth,
                                      @"ua": ua,
                                      @"userId": @(userId)}
                        returnClass:HPLabUser.class
                          needLogin:NO]
          then:^id(HPLabUser *user) {
              self.user = user;
              fulfill(user);
              return nil;
          }] catch:^(NSError *error) {
              reject(error);
          }];
    }];
}

- (FBLPromise *)logout
{
    return [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock reject) {
        [[[[HPApi instance] request:@"/user/logout"
                             params:nil]
          then:^id(id data) {
              self.user = nil;
              fulfill(nil);
              return nil;
          }] catch:^(NSError *error) {
              reject(error);
          }];
    }];
}

- (void)debug
{
    [[[[HPApi instance] request:@"/user/debug"
                         params:nil
                    returnClass:nil] then:^id(id data) {
        DDLogInfo(@"user debug: %@", data);
        return nil;
    }] catch:^(NSError *error) {
        DDLogError(@"user debug: %@", error);
    }];
}

@end
