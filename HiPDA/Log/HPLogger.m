//
//  HPLogger.m
//  HiPDA
//
//  Created by Jiangfan on 2017/4/26.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPLogger.h"
#import "HPLoggerFormatter.h"
#import <SSZipArchive/SSZipArchive.h>

@implementation HPLogger

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifdef DEBUG
        [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
        [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs
#endif
        DDFileLogger *fileLogger = [[DDFileLogger alloc] init]; // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        fileLogger.logFormatter = [[HPFileLoggerFormatter alloc] init];
        [DDLog addLogger:fileLogger];
    });
}

+ (void)getZipFile:(void (^)(NSString *path))complete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [DDLog flushLog];
        
        __block DDFileLogger *fileLogger = nil;
        [[DDLog allLoggers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:DDFileLogger.class]) {
                fileLogger = obj;
                *stop = YES;
            }
        }];
        NSArray *files = [fileLogger.logFileManager sortedLogFilePaths];
        
        NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [docsdir stringByAppendingString:@"/LogZip"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        NSString *suffix = [formatter stringFromDate:[NSDate date]];
        
        NSString *zipPath = [NSString stringWithFormat:@"%@/log_%@.zip", path, suffix];
        BOOL success = [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:files];
        NSAssert(success, @"zip file error");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            complete(zipPath);
        });
    });
}

@end
