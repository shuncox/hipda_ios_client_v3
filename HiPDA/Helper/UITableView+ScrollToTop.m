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
//    not working on iPhone X
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self setContentOffset:CGPointMake(0.0f, -self.contentInset.top) animated:NO];
//    });
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.dataSource tableView:self numberOfRowsInSection:0] > 0) {
            NSIndexPath* top = [NSIndexPath indexPathForRow:0 inSection:0];
            [self scrollToRowAtIndexPath:top atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    });
}

@end
