//
//  NSError+HPError.m
//  HiPDA
//
//  Created by Jichao Wu on 15/10/29.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "NSError+HPError.h"
#import "HPHttpClient.h"

@implementation HPCrawlerErrorContext
@end

@implementation NSError (HPError)
+ (instancetype)errorWithErrorCode:(NSInteger)code errorMsg:(NSString *)errorMsg
{
    return [[NSError alloc]
            initWithDomain:@".hi-pda.com"
            code:code
            userInfo:@{NSLocalizedDescriptionKey:errorMsg?:@"未知错误"}];
}

+ (instancetype)crawlerErrorWithContext:(HPCrawlerErrorContext *)context
{
    return   [[NSError alloc]
              initWithDomain:@".hi-pda.com"
              code:HPERROR_CRAWLER_CODE
              userInfo:@{NSLocalizedDescriptionKey:@"爬虫错误", @"context": context}];
}

- (BOOL)isNeedBindError
{
    if (self.code == HPERROR_NEED_BIND_CODE) {
        return YES;
    }
    
    if (self.userInfo && self.userInfo[AFNetworkingOperationFailingURLResponseErrorKey]) {
        NSHTTPURLResponse *resp = self.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSDictionary *headers = resp.allHeaderFields;
        if (resp.statusCode == 302
            && headers[@"Location"]
            && [headers[@"Location"] rangeOfString:@"memcp.php?action=bind"].location != NSNotFound) {
            return YES;
        }
    }
    
    return NO;
}
@end
