//
//  HPSubViewController.m
//  HiPDA
//
//  Created by Jiangfan on 2018/8/21.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPSubViewController.h"
#import "HPLabGuideViewController.h"

@interface HPSubViewController ()

@end

@implementation HPSubViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"订阅";
    
    [self addRevealActionBI];
    [self addRefreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self addGuesture];
    [super viewWillAppear:animated];
    
    [self presentViewController:[HPCommon swipeableNVCWithRootVC:[HPLabGuideViewController new]]
                       animated:YES
                     completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self removeGuesture];
    [super viewWillDisappear:animated];
}

#pragma mark -
- (void)load
{

}

- (void)refresh:(id)sender
{

}

- (void)setup {

}


@end
