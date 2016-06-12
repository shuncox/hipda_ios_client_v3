//
//  UITableView+ScrollToTop.m
//  HiPDA
//
//  Created by Jiangfan on 16/6/12.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "UITableView+ScrollToTop.h"

@implementation UITableView (ScrollToTop)

- (void)hp_scrollToTop
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setContentOffset:CGPointMake(0.0f, -self.contentInset.top) animated:NO];
    });
}

@end
