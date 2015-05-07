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

@interface HPHttpClient()
@property (nonatomic, assign)NSInteger dnsErrorCount;
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
    [self setDefaultHeader:@"User-Agent" value:@"Mozilla/5.0 (iPhone; CPU iPhone OS 7_0_3 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11B508 Safari/9537.53"];
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
                   
                   [SVProgressHUD showErrorWithStatus:@"DNS解析错误, 正在重试中...\n您也许需要更换DNS, 可能是论坛上的联通高层又调皮了..." ];
                   
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
                       [self getPath:path parameters:parameters success:success failure:failure];
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
    
    return request;
}



+ (NSString *)GBKresponse2String:(id) responseObject {
    
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    
    NSString *src = [[NSString alloc] initWithData:responseObject encoding:gbkEncoding];
    
    if (!src) src = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
    
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

@end
