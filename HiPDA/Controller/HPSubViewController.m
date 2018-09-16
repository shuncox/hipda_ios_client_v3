//
//  HPSubViewController.m
//  HiPDA
//
//  Created by Jiangfan on 2018/8/21.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPSubViewController.h"
#import "HPLabGuideViewController.h"
#import "UIScrollView+SVInfiniteScrolling.h"
#import "HPSubTableViewCell.h"
#import "HPApi.h"
#import "HPApiPage.h"
#import "HPApiSubFeed.h"
#import "SVProgressHUD.h"
#import "HPRouter.h"
#import "UIAlertView+Blocks.h"
#import "HPSubManageViewController.h"

@interface HPSubViewController ()

// data
@property (nonatomic, strong) HPApiPage *page;
@property (nonatomic, strong) NSMutableArray *list;

@end

@implementation HPSubViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _list = [@[] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"订阅";
    
    [self.tableView registerClass:HPSubTableViewCell.class forCellReuseIdentifier:NSStringFromClass(HPSubTableViewCell.class)];
    
    [self addRevealActionBI];
    [self addRefreshControl];
    
    UIBarButtonItem *manageButton = [[UIBarButtonItem alloc] initWithTitle:@"管理订阅"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(goToManagePage)];
    self.navigationItem.rightBarButtonItem = manageButton;
    

    @weakify(self);
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        @strongify(self);
        [self loadMore];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self addGuesture];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self removeGuesture];
    [super viewWillDisappear:animated];
}

#pragma mark -

- (void)setup
{
    
}

- (FBLPromise<HPApiPage *> *)getPage:(int)pageIndex
{
    return [[HPApi instance] request:@"/sub/feed"
                              params:@{@"pageIndex": @(pageIndex)}
                       modelsOfClass:HPApiSubFeed.class];
}

- (void)refresh:(id)sender
{
    @weakify(self);
    [self getPage:0]
    .then(^id(HPApiPage *page) {
        @strongify(self);
        self.page = page;
        [self.list removeAllObjects];
        [self.list addObjectsFromArray:page.list];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        if (!page.list.count) {
            [self showTip];
        }
        return page;
    }).catch(^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [self.refreshControl endRefreshing];
    });
}

- (void)loadMore
{
    if (!self.page || self.page.isEnd || self.refreshControl.refreshing) {
        [self.tableView.infiniteScrollingView stopAnimating];
        return;
    }
    
    @weakify(self);
    [self getPage:self.page.pageIndex + 1]
    .then(^id(HPApiPage *page) {
        @strongify(self);
        self.page = page;
        [self.list addObjectsFromArray:page.list];
        [self.tableView reloadData];
        [self.tableView.infiniteScrollingView stopAnimating];
        return page;
    }).catch(^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [self.tableView.infiniteScrollingView stopAnimating];
    });
}

- (void)showTip
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"目前还没有命中订阅关键词或用户的帖子"
                                                       delegate:nil
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"管理订阅", nil];
    [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [self goToManagePage];
        }
    }];
}

- (void)goToManagePage
{
    HPSubManageViewController *vc = [HPSubManageViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HPSubTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(HPSubTableViewCell.class)
                                                            forIndexPath:indexPath];
    
    HPApiSubFeed *feed = [self.list objectAtIndex:indexPath.row];
    [cell setFeed:feed];
    return cell;
}

- (double)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HPApiSubFeed *feed = [self.list objectAtIndex:indexPath.row];
    [[HPRouter instance] routeTo:@{@"tid": @(feed.threadInfo.tid)}];
}

@end
