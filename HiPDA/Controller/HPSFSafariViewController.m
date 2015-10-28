//
//  HPSFSafariViewController.m
//  HiPDA
//
//  Created by Jichao Wu on 15/10/28.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "HPSFSafariViewController.h"

@implementation HPSFSafariViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillAppear:animated];
}

@end