//
//  HPLogger.m
//  HiPDA
//
//  Created by Jiangfan on 2017/4/26.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPLogger.h"
#import "HPLoggerFormatter.h"

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

@end
