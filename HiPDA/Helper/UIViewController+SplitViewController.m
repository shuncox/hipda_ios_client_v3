//
//  UIViewController+SplitViewController.m
//  HiPDA
//
//  Created by Jichao Wu on 15/8/23.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "UIViewController+SplitViewController.h"

@implementation UIViewController (SplitViewController)

- (void)hp_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSParameterAssert(viewController);
    
    BOOL sendToDetail = IS_IPAD
    && self.splitViewController.viewControllers.count == 2
    && [self.splitViewController.viewControllers[1] isKindOfClass:UINavigationController.class];
    
    if (sendToDetail) {
        UINavigationController *n = self.splitViewController.viewControllers[1];
        [n setViewControllers:@[viewController] animated:NO];
    } else {
        [self.navigationController pushViewController:viewController animated:animated];
    }
}

@end
