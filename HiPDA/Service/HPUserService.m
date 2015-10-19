//
//  HPUserService.m
//  HiPDA
//
//  Created by Jichao Wu on 15/10/16.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "HPUserService.h"

@implementation HPUserService
+ (HPUserService *)shared
{
    static dispatch_once_t once;
    static HPUserService *singleton;
    dispatch_once(&once, ^ { singleton = [[HPUserService alloc] init]; });
    return singleton;
}

- (void)signUpWithUsername:(NSString *)username
                  password:(NSString *)password
                     block:(AVBooleanResultBlock)block;
{
    if ([self isLogin]) {
        block(NO, [NSError errorWithDomain:@"" code:0 userInfo:@{@"NSLocalizedDescriptionKey": @"已经登录"}]);
        return;
    }
    
    AVUser *user = [AVUser new];
    user.username = username;
    user.password = password;
    [user signUpInBackgroundWithBlock:block];
}

- (void)logInWithUsername:(NSString *)username
                 password:(NSString *)password
                    block:(AVUserResultBlock)block
{
    return [AVUser logInWithUsernameInBackground:username password:password block:block];
}

- (BOOL)isLogin
{
    return [AVUser currentUser] != nil;
}

- (void)logOut
{
    return [AVUser logOut];
}

- (AVUser *)currentUser
{
    return [AVUser currentUser];
}
@end
