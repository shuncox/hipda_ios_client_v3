//
//  HPAccountPassword.h
//  HiPDA
//
//  Created by Jiangfan on 16/10/16.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPAccountCredential : NSObject

@property (nonatomic, readonly, strong) NSString *password;
@property (nonatomic, readonly, strong) NSString *questionid;
@property (nonatomic, readonly, strong) NSString *answer;

- (instancetype)initWithPassword:(NSString *)password
                      questionid:(NSString *)questionid
                          answer:(NSString *)answer;
@end

@interface HPAccountPassword : NSObject

+ (BOOL)isSetAccountFor:(NSString *)username;
+ (HPAccountCredential *)credentialFor:(NSString *)username;
+ (NSError *)setCredentialFor:(NSString *)username
                   credential:(HPAccountCredential *)credential;
+ (NSError *)clearPasswordFor:(NSString *)username;

@end
