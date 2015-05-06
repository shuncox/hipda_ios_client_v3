//
//  HPQiniuUploader.m
//  HiPDA
//
//  Created by Jichao Wu on 15/5/4.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import "HPQiniuUploader.h"
#import <QiniuSDK.h>
#import "NSString+Additions.h"

@implementation HPQiniuUploader

+ (void)updateImage:(NSData *)imageData
      progressBlock:(void (^)(CGFloat progress))progressBlock
    completionBlock:(void (^)(NSString *key, NSError *error))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        QNUploadManager *upManager = [[QNUploadManager alloc] init];
        QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:nil progressHandler: ^(NSString *key, float percent) {
            NSLog(@"progress %f", percent);
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock(percent);
            });
        } params:nil checkCrc:NO cancellationSignal:nil];
        
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"qiniu_temp_image_data"];
        [imageData writeToFile:path atomically:YES];

        NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@"unknown"];
        NSString *key = [NSString stringWithFormat:@"%@/%ld.jpg", [username hp_urlFriendlyFileName], (long)([[NSDate date] timeIntervalSince1970] * 1000)];

        [upManager putFile:path key:key token:@"1CquS-wW66-Mf_Bg6RQv5Iz0SxSjLf82wDwNClLM:auF2ND-jQzZ0uC1QuQxTAoFUnrA=:eyJzY29wZSI6ImhwY2xpZW50IiwiZGVhZGxpbmUiOjE4MDkxODQ2ODB9"
                  complete: ^(QNResponseInfo *i, NSString *k, NSDictionary *resp)
         {
             NSLog(@"%@ %@ %@", i, k, resp);
             dispatch_async(dispatch_get_main_queue(), ^{
                 NSString *url = [NSString stringWithFormat:@"%@%@", HP_QINIU_PREFIX, resp[@"key"]];
                 completionBlock(url, i.error);
             });
         } option:opt];
    });
}

@end
