//
//  HPCrashReport.h
//  HiPDA
//
//  Created by Jiangfan on 2017/3/5.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

OBJC_EXTERN void HPCrashLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

@interface HPCrashReport : NSObject

@property (class, nonatomic, getter=isCrashReportEnable, assign) BOOL crashReportEnable;

+ (void)setUp;

@end
