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
    return !![self.class credentialFor:username checkExist:YES];
}

+ (HPAccountCredential *)credentialFor:(NSString *)username
{
    return [self.class credentialFor:username checkExist:NO];
}

+ (HPAccountCredential *)credentialFor:(NSString *)username
                           checkExist:(BOOL)checkExist
{
    // 将后台读keychain的请求直接过滤
    // TODO: 上线之后看看下面的读取错误的打点还有么?
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
//        NSCAssert(NO, @"app在后台, 没有读keychain的权限");
        return nil;
    }
    
    NSError *error = nil;
    NSString *credential = [SAMKeychain passwordForService:kHPKeychainService account:username error:&error];
    
    // log
    if (error) {
        // 检查是否设置过密码(isSetAccountFor:)也调用这个方法, 但是checkExist为YES
        // 从这个路径调进来的 不报error
        if (error.code == -25300 && checkExist) {
            // do nothing
        } else {
            [Flurry logEvent:@"SAMKeychain_Read_Error"
              withParameters:@{@"desc": [NSString stringWithFormat:@"%@, %@", @(error.code), error.localizedDescription],
                               @"error": [error description],
                               @"state": @([[UIApplication sharedApplication] applicationState])}];
        }
    }
    
    // fallback
    if (error) {
        credential = [NSStandardUserDefaults stringForKey:kHPAccountUserPassword2 or:@""];
    }
    
    NSArray *arr = [credential componentsSeparatedByString:@"\n"];
    if (arr.count != 3) {
        return nil;
    }
    
    // 保存一份到userdefaults, 为了上面的fallback有用
    [NSStandardUserDefaults saveObject:credential forKey:kHPAccountUserPassword2];
    
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
    
    // fallback
//    if (error) {
//        [NSStandardUserDefaults saveObject:str forKey:kHPAccountUserPassword2];
//    }
    
    // 打点统计到, keychain set从未出错, read每天上千次出错, 那么set没出错过, userdefaults里肯定没有数据
    // 所以在未查明问题之前, 默认userdefaults保存一份数据
    [NSStandardUserDefaults saveObject:str forKey:kHPAccountUserPassword2];
    
    // log
    if (error) {
        [Flurry logEvent:@"SAMKeychain_Set_Error"
          withParameters:@{@"desc": [NSString stringWithFormat:@"%@, %@", @(error.code), error.localizedDescription],
                           @"error": [error description],
                           @"state": @([[UIApplication sharedApplication] applicationState])}];
    }
    
    return error;
}

+ (NSError *)clearPasswordFor:(NSString *)username
{
    NSError *error = nil;
    [SAMKeychain deletePasswordForService:kHPKeychainService account:username error:&error];
    [NSStandardUserDefaults saveObject:nil forKey:kHPAccountUserPassword2];
    
    // log
    if (error) {
        [Flurry logEvent:@"SAMKeychain_Delete_Error"
          withParameters:@{@"desc": [NSString stringWithFormat:@"%@, %@", @(error.code), error.localizedDescription],
                           @"error": [error description],
                           @"state": @([[UIApplication sharedApplication] applicationState])}];
    }
    
    return error;
}


@end
