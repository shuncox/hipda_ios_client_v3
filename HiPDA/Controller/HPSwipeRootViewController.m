//
//  HPSwipeRootViewController.m
//  HiPDA
//
//  Created by Jichao Wu on 15/10/28.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "HPSwipeRootViewController.h"

@interface HPSwipeRootViewController()

@end

@implementation HPSwipeRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}

@end
