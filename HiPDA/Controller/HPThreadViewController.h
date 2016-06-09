//
//  HPThreadViewController.h
//  HiPDA
//
//  Created by wujichao on 13-11-11.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPViewController.h"

@interface HPThreadViewController : HPTableViewController

- (id)initDefaultForum:(NSInteger)fid title:(NSString *)title;
- (void)refresh:(in)sender;
- (void)loadForum:(NSInteger)fid title:(NSString *)title;
- (void)revealToggle:(id)sender;

@end
