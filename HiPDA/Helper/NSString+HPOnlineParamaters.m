//
//  NSString+HPOnlineParamaters.m
//  HiPDA
//
//  Created by Jichao Wu on 15/11/11.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "NSString+HPOnlineParamaters.h"

@implementation NSString (HPOnlineParamaters)
- (NSDictionary *)onlineParamaters
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
    NSArray *list = [self componentsSeparatedByString:@","];
    for (NSString *s in list) {
        if (!s.length) continue;
        
        NSArray *a = [s componentsSeparatedByString:@"="];
        if (a.count != 2) continue;
        NSString *key = a[0];
        NSString *value = a[1];
        
        if (!key.length) continue;
        //if (!value.length) continue;
        
        // {timestamp} -> new Date().getTime() (1447232054090)
        if ([value isEqualToString:@"{timestamp}"]) {
            NSTimeInterval t = [[NSDate date] timeIntervalSince1970];
            value = [NSString stringWithFormat:@"%@", @((long long)(t * 1000))];
        }
        
        [d setObject:value forKey:key];
    }
    
    return [d copy];
}

+ (void)test_onlineParamaters
{
    for (NSString *s in @[@"a={timestamp}",
                          @"a=123a",
                          @"a=",
                          @"=a",
                          @"=",
                          @"a={timestamp},b=fff",
                          @"a={timestamp},b=fff,",
                          @"a=111111,",
                ]) {
        NSLog(@"%@ -> %@", s, [s onlineParamaters]);
    }
}
@end
