//
//  HPApiSubFeed.m
//  HiPDA
//
//  Created by Jiangfan on 2018/9/15.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPApiSubFeed.h"

@implementation HPApiSubFeed

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{};
}

+ (NSValueTransformer *)threadInfoJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:HPApiThread.class];
}

+ (NSValueTransformer *)subByUserJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:HPApiSubByUser.class];
}

+ (NSValueTransformer *)subByKeywordJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:HPApiSubByKeyword.class];
}

@end
