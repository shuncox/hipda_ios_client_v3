//
//  HPLogger.h
//  HiPDA
//
//  Created by Jiangfan on 2017/4/26.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CocoaLumberjack/CocoaLumberjack.h>
#ifdef DEBUG
    static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
    static const DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif

@interface HPLogger : NSObject

+ (void)getZipFile:(void (^)(NSString *path))complete;

@end
