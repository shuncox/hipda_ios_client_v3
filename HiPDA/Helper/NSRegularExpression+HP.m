//
//  NSRegularExpression+HP.m
//  HiPDA
//
//  Created by Jiangfan on 16/3/13.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "NSRegularExpression+HP.h"

@implementation NSRegularExpression (HP)

- (NSString *)firstMatchValue:(NSString*)str
{
    RxMatch *m = [self firstMatchWithDetails:str];
    if (m && m.groups.count == 2) {
        RxMatchGroup *g = m.groups[1];
        return g.value;
    }
    return nil;
}

@end
