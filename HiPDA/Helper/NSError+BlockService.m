//
//  NSError+BlockService.m
//  HiPDA
//
//  Created by Jiangfan on 16/7/23.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "NSError+BlockService.h"
#import <CloudKit/CloudKit.h>

@implementation NSError (BlockService)

- (NSString *)hp_localizedDescription
{
    switch (self.code) {
        case CKErrorNotAuthenticated:
            if ([self.localizedDescription isEqualToString:@"This request requires an authenticated account"]) {
                return @"请先在系统设置中登录iCloud账户";
            }
            if ([self.localizedDescription isEqualToString:@"CloudKit access was denied by user settings"]) {
                return @"请在系统设置中(iCloud Drive)允许HiPDA访问您的iCloud空间";
            }
        default:
            return self.localizedDescription;
    }
}

@end
