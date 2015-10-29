//
//  NSError+HPError.h
//  HiPDA
//
//  Created by Jichao Wu on 15/10/29.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>


#define HPERROR_CRAWLER_CODE (9000)
#define HPERROR_NOT_DEFAULT_THREAD_SETTING_CODE (9001)


#define HPERROR_DISCUZ_ALERT_CODE (8000)

@interface HPCrawlerErrorContext : NSObject
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *html;
@property (nonatomic, strong) NSDictionary *requestHeaders;
@property (nonatomic, strong) NSDictionary *responseHeaders;
@property (nonatomic, strong) NSArray *cookies;
@end

@interface NSError (HPError)
+ (instancetype)errorWithErrorCodeMsg:(NSInteger)code errorMsg:(NSString *)errorMsg;
+ (instancetype)crawlerErrorWithContext:(HPCrawlerErrorContext *)context;
@end
