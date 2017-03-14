//
//  HPActivityItem.m
//  HiPDA
//
//  Created by Jiangfan on 2017/3/14.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPActivityItem.h"

@interface HPActivityItem()

@property (nonatomic, strong) id item;

@end

@implementation HPActivityItem

- (instancetype)initWithItem:(id)item
{
    self = [super init];
    if (self) {
        _item = item;
    }
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController;	// called to determine data type. only the class of the return type is consulted. it should match what -itemForActivityType: returns later
{
    // 这里只看class, 所以如果item不是马上能拿到的, 可以返回一个[Clazz new]
    return self.item;
}

- (nullable id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(UIActivityType)activityType;	// called to fetch data after an activity is selected. you can return nil.
{
    if ([activityType isKindOfClass:NSString.class] && [activityType hasPrefix:@"com.tencent.xin"]) {
        return nil;
    }
    return self.item;
}

@end
