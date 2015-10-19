//
//  HPUserService.h
//  HiPDA
//
//  Created by Jichao Wu on 15/10/16.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>

@interface HPUserService : NSObject

+ (HPUserService *)shared;

- (void)signUpWithUsername:(NSString *)username
                  password:(NSString *)password
                     block:(AVBooleanResultBlock)block;

- (void)logInWithUsername:(NSString *)username
                 password:(NSString *)password
                    block:(AVUserResultBlock)block;

- (BOOL)isLogin;

- (void)logOut;

- (AVUser *)currentUser;

@end
