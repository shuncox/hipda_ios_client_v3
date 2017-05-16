//
//  HPSearchViewController.h
//  HiPDA
//
//  Created by wujichao on 13-11-22.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPBaseTableViewController.h"
#ifdef DEBUG
@class RACSignal;
#endif
@class HPUser;

@interface HPSearchViewController : HPBaseTableViewController<UISearchBarDelegate>

- (instancetype)initWithUser:(HPUser *)user;
#ifdef DEBUG
+ (RACSignal *)signalForSearchUserWithKey:(NSString *)key;
#endif
@end
