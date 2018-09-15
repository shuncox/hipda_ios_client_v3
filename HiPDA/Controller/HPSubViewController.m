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
                                                                    action:@selector(goToManagePage:)];
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
                         returnClass:HPApiPage.class
                           needLogin:NO]
    .then(^id(HPApiPage *page) {
        NSArray *list = [page modelsOfClass:HPApiSubFeed.class];
        page.content = list;
        return page;
    });
}

- (void)refresh:(id)sender
{
    @weakify(self);
    [self getPage:0]
    .then(^id(HPApiPage *page) {
        @strongify(self);
        self.page = page;
        [self.list removeAllObjects];
        [self.list addObjectsFromArray:page.content];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        return page;
    }).catch(^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [self.refreshControl endRefreshing];
    });
}

- (void)loadMore
{
    if (!self.page || self.page.last || self.refreshControl.refreshing) {
        [self.tableView.infiniteScrollingView stopAnimating];
        return;
    }
    
    @weakify(self);
    [self getPage:self.page.number + 1]
    .then(^id(HPApiPage *page) {
        @strongify(self);
        self.page = page;
        [self.list addObjectsFromArray:page.content];
        [self.tableView reloadData];
        [self.tableView.infiniteScrollingView stopAnimating];
        return page;
    }).catch(^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [self.tableView.infiniteScrollingView stopAnimating];
    });
}

- (void)goToManagePage:(id)sender
{
    
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(HPSubTableViewCell.class)
                                                            forIndexPath:indexPath];
    
    HPApiSubFeed *feed = [self.list objectAtIndex:indexPath.row];
    cell.textLabel.text = feed.threadInfo.title;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HPApiSubFeed *feed = [self.list objectAtIndex:indexPath.row];
    [[HPRouter instance] routeTo:@{@"tid": @(feed.threadInfo.tid)}];
}

@end
