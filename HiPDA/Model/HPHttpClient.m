//
//  HPHttpClient.m
//  HiPDA
//
//  Created by wujichao on 13-11-11.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPHttpClient.h"
#import "AFHTTPRequestOperation.h"
#import "HPAccount.h"
#import "HPSetting.h"
#import <SVProgressHUD.h>
#import "NSString+Additions.h"
#import "HPSettingViewController.h"//¬_¬
#import "HPThread.h"
#import "NSString+HPOnlineParamaters.h"

@interface HPHttpClient()<UIAlertViewDelegate>
@property (nonatomic, assign)NSInteger dnsErrorCount;
@property (nonatomic, strong)UIAlertView *alertView;
@property (nonatomic, assign)BOOL isCancel;
@end

@implementation HPHttpClient

+ (HPHttpClient *)sharedClient {
    static HPHttpClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[HPHttpClient alloc] initWithBaseURL:[NSURL URLWithString:kHPClientBaseURLString]];
    });
    
    /*
     * login cookies
     */
    /*
    NSArray * availableCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://www.hi-pda.com"]];
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:availableCookies];
    //NSLog(@"headers %@", headers);
    */
    /*
    NSString *Cookie = [headers objectForKey:@"Cookie"];
    NSLog(@"_sharedClient cookie %@", Cookie);
     */
    //[_sharedClient setDefaultHeader:@"Cookie" value:[headers objectForKey:@"Cookie"]];
    
    // not work?
    [_sharedClient setStringEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    
    [self setDefaultHeader:@"Host" value:HPBaseURL];
    NSString *UA = [NSString stringWithFormat:@"com.jichaowu.hipda %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [self setDefaultHeader:@"User-Agent" value:UA];
    [self setDefaultHeader:@"Accept" value:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"];
    [self setDefaultHeader:@"Accept-Encoding" value:@"gzip, deflate"];
    [self setDefaultHeader:@"Accept-Language" value:@"zh-cn"];
    
    [self setDefaultHeader:@"Referer" value:S(@"http://%@/forum/forumdisplay.php?fid=2", HPBaseURL)];
    
    self.operationQueue.maxConcurrentOperationCount = 4;
    
    return self;
}

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    // append common parameters
    NSString *s = [UMOnlineConfig getConfigParams:@"extra_parameters"] ?: @"";
    NSMutableDictionary *d = [parameters?:@{} mutableCopy];
    [d addEntriesFromDictionary:[s onlineParamaters]];
    parameters = [d copy];
    
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    path = [path stringByAddingPercentEscapesUsingEncoding:gbkEncoding];
    
    [super getPath:path
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject){
               if (self.dnsErrorCount) {
                   NSString *user = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
                   [Flurry logEvent:@"Error DNS fix" withParameters:@{@"user":user,
                                                                      @"path":path,
                                                                      @"retry_count": @(self.dnsErrorCount)}];
                   self.dnsErrorCount = 0;
               }
               success(operation, responseObject);
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (error.code == -1003) {
                   
                   NSString *tip = @"DNS解析错误, 正在重试中...(%@)\n您可以切换到后两个节点或者更换DNS";
                   if (!self.alertView) {
                       self.alertView = [[UIAlertView alloc] initWithTitle:@"DNS错误" message:S(tip, @"") delegate:self cancelButtonTitle:@"停止" otherButtonTitles:@"切换节点", nil];
                       [self.alertView show];
                   } else {
                       self.alertView.message = S(tip, @(self.dnsErrorCount));
                   }
                   
                   NSTimeInterval delay = 0.1;
                   dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
                   dispatch_after(popTime, dispatch_get_main_queue(), ^{
                       NSString *user = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
                       if (self.dnsErrorCount) {
                           [Flurry logEvent:@"Error DNS retry" withParameters:@{@"user":user,
                                                                                @"path":path,
                                                                                @"retry_count": @(self.dnsErrorCount)}];
                       } else {
                           [Flurry logEvent:@"Error DNS first" withParameters:@{@"user":user,
                                                                                @"path":path}];
                       }
                       self.dnsErrorCount += 1;
                       if (self.isCancel) {
                           self.isCancel = NO;
                       } else {
                           [self getPath:path parameters:parameters success:success failure:failure];
                       }
                   });
                   
               } else {
                   failure(operation, error);
               }
           }];
}

- (void)getPathContent:(NSString *)path
            parameters:(NSDictionary *)parameters
               success:(void (^)(AFHTTPRequestOperation *operation, NSString *html))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	[self getPath:path
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSError *error;
        NSString *content = [HPHttpClient prepareHTML:responseObject error:&error];
        //NSLog(@"content html %@", content);
        
        if (error) {
            failure(operation, error);
        } else {
            success(operation, content);
        }
    }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               ;
               //bug of hi-pda
               //no login to load forum return 500
               if (error.code == -1011 && [Setting boolForKey:HPSettingForceLogin]) {
                   error = [NSError errorWithDomain:@".hi-pda.com" code:NSURLErrorUserAuthenticationRequired userInfo:@{NSLocalizedDescriptionKey:@""}];
                   [[HPAccount sharedHPAccount] loginWithBlock:^(BOOL isLogin, NSError *err) {
                       NSLog(@"relogin %@", isLogin?@"success":@"fail");
                   }];
               }
               if (failure) failure(operation, error);
           }
    ];
}

/*
 * overwrite add cookies handle
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters {
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    
    if (!request) {
        NSLog(@"!request");
        return nil;
    }
    
    [request setHTTPShouldHandleCookies:YES];
    
    // 使用XHR绕过广告
    if ([Setting boolForKey:HPSettingEnableXHR]) {
        [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    }
    
    return request;
}



+ (NSString *)GBKresponse2String:(id) responseObject {
    
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    
    NSString *src = [[NSString alloc] initWithData:responseObject encoding:gbkEncoding];
    
    if (!src) src = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
    
    if (!src) src = [self.class gb2312Data2String:responseObject];
    
    return src;
}

/*
 * 转成 utf-8
 * 检查 是否登录
 */
+ (NSString *)prepareHTML:(id)responseObject error:(NSError **)error{
    
    NSString *src = [HPHttpClient GBKresponse2String:responseObject];
    //NSLog(@"%@", src);
    
    if ([src indexOf:@"loginform"] != -1) {
        
        // need login
        [[HPAccount sharedHPAccount] loginWithBlock:^(BOOL isLogin, NSError *err) {
            NSLog(@"relogin %@", isLogin?@"success":@"fail");
        }];
        
        if (error) {
            *error = [NSError errorWithDomain:@".hi-pda.com" code:NSURLErrorUserAuthenticationRequired userInfo:nil];
        }
    }
    
    return src;
}

#pragma mark -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.isCancel = YES;
    self.alertView = nil;
    if (buttonIndex != alertView.cancelButtonIndex) {
        // 不要鄙视我¬_¬
        HPSettingViewController *settingVC = [HPSettingViewController new];
        [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:[HPCommon NVCWithRootVC:settingVC] animated:YES completion:nil];
    }
}

#pragma mark -
- (void)cancelOperationsWithThread:(HPThread *)thread
{
    if (thread.tid <= 0) return;
    
    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
            continue;
        }
        
        NSString *url = [[[(AFHTTPRequestOperation *)operation request] URL] absoluteString];
        if ([url indexOf:@"viewthread.php"] != -1
            && [url indexOf:[NSString stringWithFormat:@"%@", @(thread.tid)]] != -1) {
            
            [operation cancel];
        }
    }
}

#pragma mark - 

// https://github.com/Maxwin-z/xsmth-newsmth/blob/284366fbbdfd97884c3c8d5877f655ef85ab78f4/newsmth/Utils/SMUtils.m#L225
// 不规范的编码...
+ (NSString *)gb2312Data2String:(NSData *)data
{
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    
    NSMutableString *result = [[NSMutableString alloc] init];
    for (size_t i = 0; i != data.length; ++i) {
        unsigned char ch1[1], ch2[2];
        [data getBytes:ch1 range:NSMakeRange(i, 1)];
        if ((int)ch1[0] < 0x7f) {
            [result appendString:[[NSString alloc] initWithBytes:ch1 length:1 encoding:NSASCIIStringEncoding]];
        } else if (i + 1 < data.length) {
            [data getBytes:ch2 range:NSMakeRange(i, 2)];
            [result appendString:[[NSString alloc] initWithBytes:ch2 length:2 encoding:enc] ?: @""];
#if DEBUG
            if (![[NSString alloc] initWithBytes:ch2 length:2 encoding:enc]) {
                char ch3[3];
                [data getBytes:ch3 range:NSMakeRange(i, MIN(3, data.length - i))];
                char ch10[10];
                [data getBytes:ch10 range:NSMakeRange(i, MIN(10, data.length - i))];
                NSLog(@"%s", ch10);
            }
#endif
            ++i;    // 2字节
        }
    }
    return result;
}

@end
