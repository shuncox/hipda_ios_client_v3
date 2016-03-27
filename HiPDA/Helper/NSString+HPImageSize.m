//
//  NSString+HPImageSize.m
//  HiPDA
//
//  Created by Jiangfan on 16/3/27.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "NSString+HPImageSize.h"

@implementation NSString (HPImageSize)

/**
 *  输入 123.12 KB  123.12 MB
 *  输出 "123.12", "12313"
 */
- (CGFloat)imageSize
{
    if ([self hasSuffix:@" KB"]) {
        return [[self stringByReplacingOccurrencesOfString:@" KB" withString:@""] doubleValue];
    } else if ([self hasSuffix:@" MB"]) {
        return [[self stringByReplacingOccurrencesOfString:@" MB" withString:@""] doubleValue] * 1024;
    } else if ([self hasSuffix:@" Bytes"]) {
        return [[self stringByReplacingOccurrencesOfString:@" Bytes" withString:@""] doubleValue] / 1024;
    } else {
        assert(0);
        return [self doubleValue];
    }
}

/**
 *  输入 123.12, 12313
 *  输出 123.12 KB  123.12 MB
 */
- (NSString *)imageSizeString
{
    double size = [self doubleValue];
    if (size > 1000) {
        return [NSString stringWithFormat:@"%.2f MB", size / 1024.f];
    } else {
        return [NSString stringWithFormat:@"%.2f KB", size];
    }
    return @"";
}


- (NSString*)getSizeString:(NSString *)aid {
    
    // , 5.31 MB) / 下载次数 0<br />http://www.hi-pda.com/forum/attachment.php?aid=2465087

    NSRange endRange = [self rangeOfString:[NSString stringWithFormat:@"aid=%@", aid]];
    if (endRange.location != NSNotFound) {
        NSRange startRange = [self rangeOfString:@", " options:NSBackwardsSearch range:NSMakeRange(0, endRange.location)];
        if (startRange.location != NSNotFound) {
            endRange = [self rangeOfString:@")" options:0 range:NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location)];
            if (endRange.location != NSNotFound) {
                return [self substringWithRange:NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length)];
            }
        }
    }
    return nil;
}
@end
