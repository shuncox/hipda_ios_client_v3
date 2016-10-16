//
//  HPAccountPassword.m
//  HiPDA
//
//  Created by Jiangfan on 16/10/16.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "HPAccountPassword.h"
#import <SAMKeychain/SAMKeychain.h>

#define kHPKeychainService @"HPAccount"
#define kHPAccountUserPassword2 @"kHPAccountUserPassword2" //keychain挂了用这个

@interface HPAccountCredential()

@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *questionid;
@property (nonatomic, strong) NSString *answer;

@end

@implementation HPAccountCredential

- (instancetype)initWithPassword:(NSString *)password
                      questionid:(NSString *)questionid
                          answer:(NSString *)answer

{
    self = [super init];
    if (self) {
        NSCParameterAssert(password.length);
        
        _password = password.length ? [password copy] : @"";
        _questionid = questionid.length ? [questionid copy] : @"";
        _answer = answer.length ? [answer copy] : @"";
    }
    return self;
}

@end

@implementation HPAccountPassword

+ (BOOL)isSetAccountFor:(NSString *)username
{
    return !![self.class credentialFor:username];
}

+ (HPAccountCredential *)credentialFor:(NSString *)username
{
    NSString *credential = [SAMKeychain passwordForService:kHPKeychainService account:username];
    NSArray *arr = [credential componentsSeparatedByString:@"\n"];
    
    if (arr.count != 3) {
        return nil;
    }
    
    NSString *password = arr[0];
    NSString *questionid = arr[1];
    NSString *answer = arr[2];
    
    return [[HPAccountCredential alloc] initWithPassword:password questionid:questionid answer:answer];
}

+ (NSError *)setCredentialFor:(NSString *)username
              credential:(HPAccountCredential *)credential
{
    NSArray *arr = @[credential.password, credential.questionid, credential.answer];
    NSString *str = [arr componentsJoinedByString:@"\n"];
    
    NSError *error = nil;
    [SAMKeychain setPassword:str forService:kHPKeychainService account:username error:&error];
    
    return error;
}

+ (NSError *)clearPasswordFor:(NSString *)username
{
    NSError *error = nil;
    [SAMKeychain deletePasswordForService:kHPKeychainService account:username error:&error];
    
    return error;
}

@end
