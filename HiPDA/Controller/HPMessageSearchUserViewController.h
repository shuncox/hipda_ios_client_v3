//
//  HPMessageSearchUserViewController.h
//  HiPDA
//
//  Created by Jiangfan on 2017/5/16.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPViewController.h"

@interface HPMessageSearchUserViewController : HPTableViewController
<
UISearchControllerDelegate,
UISearchResultsUpdating,
UISearchBarDelegate
>

@property (nonatomic, weak) UISearchController *searchController;

@end
