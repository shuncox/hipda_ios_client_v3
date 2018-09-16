//
//  HPApi.m
//  HiPDA
//
//  Created by Jiangfan on 2018/8/6.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPApi.h"
#import "HPApiResult.h"
#import <Mantle/Mantle.h>
#import "NSError+HPError.h"
#import "HPApiConfig.h"
#import "HPLabUserService.h"
#import "HPLabService.h"

@interface HPApi()

@property (nonatomic, strong) HPApiConfig *config;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation HPApi

+ (instancetype)instance;
{
    static dispatch_once_t once;
    static HPApi *singleton;
    dispatch_once(&once, ^ { singleton = [[HPApi alloc] init]; });
    return singleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _config = [HPApiConfig config];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration];
        _queue = dispatch_queue_create("com.jichaowu.HPApi", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (FBLPromise *)request:(NSString *)api
                 params:(NSDictionary *)params
{
    return [self request:api params:params returnClass:nil];
}

- (FBLPromise *)request:(NSString *)api
                 params:(NSDictionary *)params
            returnClass:(Class)returnClass
{
     return [self request:api params:params returnClass:returnClass needLogin:YES];
}

- (FBLPromise<HPApiPage *> *)request:(NSString *)api
                              params:(NSDictionary *)params
                       modelsOfClass:(Class)modelsOfClass
{
    return [self request:api
                  params:params
             returnClass:HPApiPage.class]
    .then(^id(HPApiPage *page) {
        if (!page.list) {
            return page;
        }
        NSError *error = nil;
        NSArray *list = [MTLJSONAdapter modelsOfClass:modelsOfClass fromJSONArray:page.list error:&error];
        if (error) {
            return error;
        }
        page.list = list;
        return page;
    });
}

- (FBLPromise *)request:(NSString *)api
                 params:(NSDictionary *)params
            returnClass:(Class)returnClass
              needLogin:(BOOL)needLogin
{
    if (!needLogin) {
        return [self _request:api params:params returnClass:returnClass canRetry:YES];
    }
    
    return [[HPLabUserService instance] loginIfNeeded]
    .then(^id(HPLabUser *yser) {
        return [self _request:api params:params returnClass:returnClass canRetry:YES];
    });
}

- (FBLPromise *)_request:(NSString *)api
                 params:(NSDictionary *)params
            returnClass:(Class)returnClass
               canRetry:(BOOL)canRetry
{
    FBLPromise<id> *promise = [FBLPromise onQueue:self.queue async:^(FBLPromiseFulfillBlock fulfill,
                                                                     FBLPromiseRejectBlock reject) {
        NSString *url = [self.config.baseUrl stringByAppendingString:api];
       
        NSString *token = [HPLabUserService instance].user.token;
        NSDictionary *headers = @{@"X-TOKEN": token ?: @""};
        
        DDLogInfo(@"request api: %@, params: %@", api, params);
        [self post:url params:params headers:headers
          complete:^(NSDictionary *json, NSError *error) {
              DDLogInfo(@"request api: %@, result: %@, error: %@", api, json, error);
              if (error) {
                  reject(error);
                  return;
              }
              
              NSError *json_error = nil;
              id data = [HPApi ParseJSON:json returnClass:returnClass error:&json_error];
             
              if (json_error) {
                  if (json_error.code == 401 && canRetry) { // 重新登录
                      [[HPLabUserService instance] relogin]
                      .then(^id(HPLabUser *yser) {
                          return [self _request:api params:params returnClass:returnClass canRetry:NO];
                      })
                      .then(^id(id data) {
                          fulfill(data);
                          return data;
                      })
                      .catch(^(NSError *error) {
                          reject(error);
                      });
                  } else {
                      reject(json_error);
                  }
                  return;
              }
              
              fulfill(data);
          }];
    }];
    
    return promise;
}

+ (id)ParseJSON:(NSDictionary *)json
    returnClass:(Class)returnClass
          error:(NSError **)error
{
    HPApiResult *result = [MTLJSONAdapter modelOfClass:HPApiResult.class
                                    fromJSONDictionary:json
                                                 error:error];
    if (*error) {
        return nil;
    }
    
    if (result.code != 0) {
        *error = [NSError errorWithErrorCode:result.code errorMsg:result.message];
        return nil;
    }
    
    id data = result.data;
    if (returnClass) {
        data = [MTLJSONAdapter modelOfClass:returnClass
                         fromJSONDictionary:result.data
                                      error:error];
        if (*error) {
            return nil;
        }
    }
    return data;
}

- (NSURLSessionDataTask *)post:(NSString *)url
                        params:(NSDictionary *)params
                       headers:(NSDictionary *)headers
                      complete:(void (^)(NSDictionary *json, NSError *error))complete;
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    NSString *UA = [NSString stringWithFormat:@"com.jichaowu.hipda %@ %@",
                    [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                    [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    [request addValue:UA forHTTPHeaderField:@"User-Agent"];
    if (headers) {
        [request setAllHTTPHeaderFields:headers];
    }
    
    [request setHTTPMethod:@"POST"];
    if (params) {
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        NSAssert(!error, @"序列化失败");
        [request setHTTPBody:data];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError * error) {
        if (error) {
            complete(nil, error);
            return;
        }
        if ([response isKindOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
            if (r.statusCode != 200) {
                NSError *e = [NSError errorWithErrorCode:r.statusCode errorMsg:[NSHTTPURLResponse localizedStringForStatusCode:r.statusCode]];
                complete(nil, e);
                return;
            }
        }
        NSError *json_error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&json_error];
        NSAssert(!error, @"反序列化失败");
        if (json_error) {
            complete(nil, json_error);
            return;
        }
        complete(json, nil);
    }];
    
    [task resume];
    return task;
}

@end
