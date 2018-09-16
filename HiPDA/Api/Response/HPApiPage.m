//
//  HPApiPage.m
//  HiPDA
//
//  Created by Jiangfan on 2018/9/15.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPApiPage.h"

@implementation HPApiPage

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{};
}

- (BOOL)isEnd
{
    return self.pageIndex + 1 >= self.totalPages;
}

@end
