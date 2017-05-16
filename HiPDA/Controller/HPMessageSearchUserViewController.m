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
#import "HPUserViewController.h"

// TODO
#import "HPSearchViewController.h"

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
    
    @weakify(self);
    [[[[[textSignal
         filter:^BOOL(NSString *text) {
             return text.length > 0;
         }] throttle:0.3]
       flattenMap:^RACStream *(NSString *key) {
           return [HPSearchViewController signalForSearchUserWithKey:key];
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
    
    HPUser *user = [[self.results objectAtIndex:indexPath.row] objectForKey:@"user"];
    [cell.textLabel setText:user.username];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HPUser *user = [[self.results objectAtIndex:indexPath.row] objectForKey:@"user"];
    
    HPUserViewController *uvc = [HPUserViewController new];
    uvc.username = user.username;
    uvc.uid = user.uid;
    
    [self.searchController.searchBar resignFirstResponder];
    self.searchController.searchBar.hidden = YES;
    
    [self.navigationController pushViewController:uvc animated:YES];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    ;
}

@end
