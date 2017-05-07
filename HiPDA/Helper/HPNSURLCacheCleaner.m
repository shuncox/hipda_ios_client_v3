//
//  HPNSURLCacheCleaner.m
//  HiPDA
//
//  Created by Jiangfan on 2017/3/12.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPNSURLCacheCleaner.h"
#import <WebKit/WKWebsiteDataStore.h>

@implementation HPNSURLCacheCleaner

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backgroundCleanDisk)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

/**
 *  清理fsCachedData
 *  https://forums.developer.apple.com/thread/69286
 */
+ (void)backgroundCleanDisk
{
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // UIWebView
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        
        if (!IOS9_OR_LATER) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [application endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            });
            return;
        }
        // WKWekView
        NSSet *websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [application endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            });
        }];
    });
}

@end
