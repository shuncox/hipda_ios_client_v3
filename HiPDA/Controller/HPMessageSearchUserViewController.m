//
//  HPMessageSearchUserViewController.m
//  HiPDA
//
//  Created by Jiangfan on 2017/5/16.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPMessageSearchUserViewController.h"
#import <ReactiveCocoa.h>
#import "UITableView+ScrollToTop.h"
#import "HPUser.h"
#import "HPMessageDetailViewController.h"
#import "HPUserSearch.h"

static NSString * const CellIdentifier = @"CellWithIdentifier";

@interface HPMessageSearchUserViewController ()

@property (nonatomic, strong) NSArray *results;

@end

@implementation HPMessageSearchUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"搜索用户";
    
    self.results = @[];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    RACSignal *textSignal = [[self rac_signalForSelector:@selector(searchBar:textDidChange:)
                                            fromProtocol:@protocol(UISearchBarDelegate)] map:^id(RACTuple *tuple) {
        return tuple.second;
    }];
    
    if ([UIDevice hp_isiPhoneX]) {
        // 这个地方的 searchbar 使用的姿势不是很标准, 所以系统默认的调整有些问题, 禁用系统的自动跳过, 我们自己调整一下.
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        UIEdgeInsets insets = self.tableView.contentInset;
        insets.bottom = [UIDevice hp_safeAreaInsets].bottom;
        self.tableView.contentInset = insets;
    }
    
    @weakify(self);
    [[[[[textSignal
         filter:^BOOL(NSString *text) {
             return text.length > 0;
         }] throttle:0.3]
       flattenMap:^RACStream *(NSString *key) {
           return [HPUserSearch signalForSearchUserWithKey:key];
       }]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSArray *results) {
         @strongify(self);
         self.results = results;
         [self.tableView reloadData];
         [self.tableView hp_scrollToTop];
         [self.tableView flashScrollIndicators];
     }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.searchController.searchBar.hidden = NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    HPUser *user = [self.results objectAtIndex:indexPath.row];
    [cell.textLabel setText:user.username];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.searchController.searchBar resignFirstResponder];
    self.searchController.searchBar.hidden = YES;
    
    HPUser *user = [self.results objectAtIndex:indexPath.row];
    
    HPMessageDetailViewController *detailViewController = [[HPMessageDetailViewController alloc] init];
    detailViewController.user = user;
    
    [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    ;
}

@end
