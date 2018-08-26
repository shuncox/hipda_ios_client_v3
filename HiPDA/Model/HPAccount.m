//
//  HPAccount.m
//  HiPDA
//
//  Created by wujichao on 13-11-11.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPCommon.h"
#import "HPAccount.h"
#import "HPHttpClient.h"
#import "HPSetting.h"
#import "HPTheme.h"
#import "RegExCategories.h"
#import "HPMessage.h"
#import "HPAccountPassword.h"

#import "HPRearViewController.h"

#import "NSString+Additions.h"
#import "AFHTTPRequestOperation.h"
#import "NSHTTPCookieStorage+info.h"

#import "HPLoginViewController.h"

#import <AudioToolbox/AudioToolbox.h>

@interface HPAccount ()

@property (nonatomic, strong) NSTimer *checkTimer;
@property (nonatomic, strong) HPHttpClient *checkPmClient;

@end

@implementation HPAccount


+ (HPAccount *)sharedHPAccount {
    static HPAccount *_sharedHPAccount = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedHPAccount = [[HPAccount alloc] init];
        _sharedHPAccount.checkPmClient = [[HPHttpClient alloc] initWithBaseURL:[NSURL URLWithString:HP_BASE_URL]];
    });
    
    return _sharedHPAccount;
}

+ (BOOL)isSetAccount {
    NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
    
    return [username length] && [HPAccountPassword isSetAccountFor:username];
}

+ (BOOL)isAccountForReviewer
{
    NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
    return [username isEqualToString:@"wujichao"];
}

+ (BOOL)isMasterAccount
{
    NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
    return [username isEqualToString:@"geka"];
}

- (void)loginWithBlock:(void (^)(BOOL isLogin, NSError *error))block {
    [self _loginWithBlock:^(BOOL isLogin, NSError *error) {
        
        block(isLogin, error);
        
        if (isLogin) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kHPUserLoginSuccess object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kHPUserLoginError object:nil userInfo:@{@"error":error}];
        }
    }];
}

- (void)_loginWithBlock:(void (^)(BOOL isLogin, NSError *error))block {
    
    // acquire account info
    if (![HPAccount isSetAccount]) {
        HPLoginViewController *loginvc = [[HPLoginViewController alloc] init];
        
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:[HPCommon NVCWithRootVC:loginvc] animated:YES completion:^{
            ;
        }];
        block(NO, [NSError errorWithDomain:@".hi-pda.com" code:kHPNoAccountCode userInfo:nil]);
        return;
    }
    
    DDLogInfo(@"login step1");
    [[HPHttpClient sharedClient] getPath:@"forum/logging.php?action=login" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *src = [HPHttpClient GBKresponse2String:responseObject];
        
        NSString *formhash = [src stringBetweenString:@"formhash\" value=\"" andString:@"\""];
        if (formhash) {
            
            DDLogInfo(@"login get formhash %@", formhash);
            [self _loginWithFormhash:formhash block:block];
            
        } else {
            
            NSString *alert_info = [src stringBetweenString:@"<div class=\"alert_info\">\n<p>" andString:@"</p>"];
            NSString *alert_error = [src stringBetweenString:@"<div class=\"alert_error\">\n<p>" andString:@"</p></div>"];
            NSString *msg = nil;
            if (alert_info) msg = alert_info;
            else if (alert_error) msg = alert_error;
            else msg = src;
            
            if (block) {
                DDLogWarn(@"login step1 找不到token %@", src);
                block(NO, [NSError errorWithDomain:@".hi-pda.com" code:NSURLErrorUserAuthenticationRequired userInfo:@{NSLocalizedDescriptionKey:S(@"找不到token, 错误信息: %@", msg)}]);
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(NO, error);
        }
    }];
}

- (void)_loginWithFormhash:(NSString *)formhash block:(void (^)(BOOL isLogin, NSError *error))block {
    
    NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
    
    HPAccountCredential *credential = [HPAccountPassword credentialFor:username];
    if (!credential) {
        DDLogWarn(@"login credential does not contain 3 components");
        block(NO, [NSError errorWithDomain:@".hi-pda.com" code:NSURLErrorUserAuthenticationRequired userInfo:@{NSLocalizedDescriptionKey:@"Keychain出问题了"}]);
        return;
    }
    NSString *password = credential.password;
    NSString *questionid = credential.questionid;
    NSString *answer = credential.answer;
    
    NSDictionary *parameters = @{
         @"loginfield":@"username",
         @"username":username,
         @"password":password,
         @"questionid":questionid,
         @"answer":answer,
         @"cookietime":@"2592000",
         @"referer":S(@"%@/forum/index.php", HP_BASE_URL),
         @"formhash":formhash
    };
    
    DDLogInfo(@"login step2 parameters %@", parameters);
    
    [[HPHttpClient sharedClient] postPath:@"forum/logging.php?action=login&loginsubmit=yes&inajax=1&inajax=1" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *html = [HPHttpClient GBKresponse2String:responseObject];
        //NSLog(@"login html : %@",html);
        
        BOOL isSuccess = ([html indexOf:@"欢迎您回来"] != -1);
        NSString *errMsg = [html stringBetweenString:@"<![CDATA[" andString:@"]]"];
        if (!errMsg) errMsg = html;
        if (!html) errMsg = @"null response";
       
        if (block) {
            block(isSuccess, [NSError errorWithDomain:@".hi-pda.com" code:NSURLErrorUserAuthenticationRequired userInfo:@{NSLocalizedDescriptionKey:errMsg}]);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(NO, error);
        }
    }];
}

/*
 * 登录成功会先调用 [Setting loadSetting] 加载设置, 然后发送 kHPUserLoginSuccess 通知
 * 登出会先清除设置, 同时调用 [Setting loadDefaults] 加载默认设置, 然后发送 kHPUserLogout 通知
 */
- (void)logout {
    
    NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
    
    // clear username
    [NSStandardUserDefaults saveObject:@"" forKey:kHPAccountUserName];
    // clear password
    [HPAccountPassword clearPasswordFor:username];

    //clear userDefaults
    // 有些不清空
    NSMutableDictionary *keepSettings = [NSMutableDictionary dictionary];
    NSDictionary *d = [NSStandardUserDefaults dictionaryRepresentation];
    [d enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        // 用户的设置不清空
        if ([key hasPrefix:HPSettingDic]) {
            [keepSettings setObject:obj forKey:key];
        }
    }];
    //
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    //
    [keepSettings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [NSStandardUserDefaults setObject:obj forKey:key];
    }];
    [NSStandardUserDefaults synchronize];
    
    
    //
    [Setting loadDefaults];

    // clear cookies
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }
    
    DDLogInfo(@"logout done");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kHPUserLogout object:nil];
}




//fake
- (void)registerWithBlock:(void (^)(BOOL isLogin, NSError *error))block {
    
    NSString *loginPath = @"forum/register.php";
    [[HPHttpClient sharedClient] getPath:loginPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (block) {
            block(YES, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(NO, error);
        }
    }];
}

- (void)startCheckWithDelay:(NSTimeInterval)delay {
    DDLogInfo(@"startCheckWithDelay %f", delay);
    if (delay == 0.f) {
        [self _checkMsgAndNoticeStep1];
    } else {
        [self performSelector:@selector(checkMsgAndNotice) withObject:nil afterDelay:delay];
    }
}


- (void)checkMsgAndNotice {
    
    _checkTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector: @selector(_checkMsgAndNoticeStep1) userInfo:nil repeats:YES];
    //_checkTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector: @selector(_checkMsgAndNoticeStep1) userInfo:nil repeats:YES];
    [_checkTimer fire];
}

- (void)_checkMsgAndNoticeStep1 {
    
    DDLogInfo(@"_checkMsgAndNoticeStep1...");
    
    NSTimeInterval t = [[NSDate date] timeIntervalSince1970];
    NSString *randomPath = [NSString stringWithFormat:@"forum/pm.php?checknewpm=%d&inajax=1&ajaxtarget=myprompt_check", (int)t];
    //NSLog(@"%@", randomPath);
    
    [self.checkPmClient getPath:randomPath
                              parameters:nil
                                 success:
     ^(AFHTTPRequestOperation *operation, id responseObject) {
        
         
         NSString *html = [HPHttpClient GBKresponse2String:responseObject];
         if ([html indexOf:@"您还未登录"] == -1) {
             
             [self _checkMsgAndNoticeStep2];
             
         } else {
             
             [[HPAccount sharedHPAccount] loginWithBlock:^(BOOL isLogin, NSError *err) {
                 DDLogInfo(@"relogin %@", isLogin?@"success":@"fail");
                 
                 if (isLogin) {
                     
                     [self _checkMsgAndNoticeStep2];
                     
                 } else {
                     
                     if (_noticeRetrieveBlock) {
                         _noticeRetrieveBlock(UIBackgroundFetchResultFailed);
                         _noticeRetrieveBlock = nil;
                     }
                 }
             }];
         }
     }
                                 failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        DDLogInfo(@"_checkMsgAndNoticeSetp1 error %@", error);
        if (_noticeRetrieveBlock) {
            _noticeRetrieveBlock(UIBackgroundFetchResultFailed);
            _noticeRetrieveBlock = nil;
        }
    }];
}

- (void)_checkMsgAndNoticeStep2 {
    
     DDLogInfo(@"_checkMsgAndNoticeStep2...");
    
    [self.checkPmClient getPathContent:@"forum/memcp.php?action=credits" parameters:nil success:^(AFHTTPRequestOperation *operation, NSString *html) {
        //NSLog(@"checkMsgAndNotice %@", html);
        
        NSInteger pm_count = 0, notice_count = 0;
        RxMatch *m1 = [RX(@"私人消息 \\((\\d+)\\)") firstMatchWithDetails:html];
        RxMatch *m2 = [RX(@"帖子消息 \\((\\d+)\\)") firstMatchWithDetails:html];
        
        if (m1) {
            RxMatchGroup *g1 = [m1.groups objectAtIndex:1];
            pm_count = [g1.value integerValue];
            DDLogInfo(@"get new pm_count %d", pm_count);
        }
        if (m2) {
            RxMatchGroup *g2 = [m2.groups objectAtIndex:1];
            notice_count = [g2.value integerValue];
            DDLogInfo(@"get new notice_count %d", notice_count);
        }
        
        [Setting saveInteger:pm_count forKey:HPPMCount];
        [Setting saveInteger:notice_count forKey:HPNoticeCount];
        
        if (pm_count || notice_count) {
            [self addLocalNotification];
            
            if (_noticeRetrieveBlock) {
                _noticeRetrieveBlock(UIBackgroundFetchResultNewData);
                _noticeRetrieveBlock = nil;
            }
        } else {
            if (_noticeRetrieveBlock) {
                _noticeRetrieveBlock(UIBackgroundFetchResultNoData);
                _noticeRetrieveBlock = nil;
            }
        }
        
        [[HPRearViewController sharedRearVC] updateBadgeNumber];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogWarn(@"_checkMsgAndNoticeSetp2 error %@", error);
        if (_noticeRetrieveBlock) {
            _noticeRetrieveBlock(UIBackgroundFetchResultFailed);
            _noticeRetrieveBlock = nil;
        }
    }];
}

- (void)checkMsgAndNoticeFromAnyPage:(NSString *)html {
    //NSLog(@"checkMsgAndNotice %@", html);
    
    NSInteger pm_count = 0, notice_count = 0;
    RxMatch *m1 = [RX(@"私人消息 \\((\\d+)\\)") firstMatchWithDetails:html];
    RxMatch *m2 = [RX(@"帖子消息 \\((\\d+)\\)") firstMatchWithDetails:html];
    
    if (m1) {
        RxMatchGroup *g1 = [m1.groups objectAtIndex:1];
        pm_count = [g1.value integerValue];
        DDLogInfo(@"get new pm_count %d", pm_count);
    }
    if (m2) {
        RxMatchGroup *g2 = [m2.groups objectAtIndex:1];
        notice_count = [g2.value integerValue];
        DDLogInfo(@"get new notice_count %d", notice_count);
    }
    
    if (pm_count || notice_count) {
        [Setting saveInteger:pm_count forKey:HPPMCount];
        [Setting saveInteger:notice_count forKey:HPNoticeCount];
        [[HPRearViewController sharedRearVC] updateBadgeNumber];
    }
}

- (void)addLocalNotification {
    
    // clear older
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    NSInteger pm_count = [Setting integerForKey:HPPMCount];
    NSInteger notice_count = [Setting integerForKey:HPNoticeCount];
    
    NSString *msg = nil;
    if (pm_count > 0) {
        msg = S(@"您有新的短消息(%d)", pm_count);
    } else if (notice_count > 0){
        msg = S(@"您有新的帖子消息(%d)", notice_count);
    } else {
        //
        return;
    }
    
    // Creates the notification
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:1];
    localNotification.alertBody = msg;
    localNotification.repeatInterval = 0;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = [[HPAccount sharedHPAccount] badgeNumber];
    
    // And then sets it
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


- (NSInteger)badgeNumber {
    NSInteger pm_count = [Setting integerForKey:HPPMCount];
    NSInteger notice_count = [Setting integerForKey:HPNoticeCount];
    return pm_count+notice_count;
}


- (BOOL)checkLocalNotificationPermission {
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        
        UIUserNotificationSettings *s = [[UIApplication sharedApplication] currentUserNotificationSettings];
        DDLogInfo(@"UIUserNotificationSettings %@", s);
        if (s.types == UIUserNotificationTypeNone) {
            return NO;
        } else {
            return YES;
        }
    }
    return YES;
}

- (void)askLocalNotificationPermission {
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    [NSStandardUserDefaults saveBool:YES forKey:kHPAskNotificationPermission];
}

@end
