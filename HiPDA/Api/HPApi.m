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

@interface HPApi()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) dispatch_queue_t queue;;

@end

@implementation HPApi

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration];
        _queue = dispatch_queue_create("com.jichaowu.HPApi", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (FBLPromise *)request:(NSString *)api
                 params:(NSDictionary *)params
            returnClass:(Class)returnClass
{
    FBLPromise<id> *promise = [FBLPromise onQueue:self.queue async:^(FBLPromiseFulfillBlock fulfill,
                                                                     FBLPromiseRejectBlock reject) {
        NSString *url = [@"http://localhost:8080/api" stringByAppendingString:api];
        NSDictionary *headers = @{@"X-TOKEN": @"644982_ddb8f780014d48fcbdd178f292f9fd57"};
        [self post:url params:params headers:headers
          complete:^(NSDictionary *json, NSError *error) {
              if (error) {
                  reject(error);
                  return;
              }
              
              NSError *json_error = nil;
              HPApiResult *result = [MTLJSONAdapter modelOfClass:HPApiResult.class
                                              fromJSONDictionary:json
                                                           error:&json_error];
              if (json_error) {
                  reject(json_error);
                  return;
              }
              
              if (!result.data) {
                  NSError *bizError = [NSError errorWithErrorCode:result.code errorMsg:result.message];
                  reject(bizError);
                  return;
              }
              
              id data = [MTLJSONAdapter modelOfClass:returnClass
                                  fromJSONDictionary:result.data
                                               error:&json_error];
              if (json_error) {
                  reject(json_error);
                  return;
              }
              
              fulfill(data);
          }];
    }];
    
    return promise;
}

- (NSURLSessionDataTask *)post:(NSString *)url
                        params:(NSDictionary *)params
                       headers:(NSDictionary *)headers
                      complete:(void (^)(NSDictionary *json, NSError *error))complete;
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
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
