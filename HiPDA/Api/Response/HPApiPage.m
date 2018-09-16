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

- (NSArray *)modelsOfClass:(Class)clazz
{
    if (!self.list) {
        return nil;
    }
    NSError *error = nil;
    NSArray *list = [MTLJSONAdapter modelsOfClass:clazz fromJSONArray:self.list error:&error];
    NSParameterAssert(!error);
    return list;
}

@end
