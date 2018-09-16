//
//  HPSubManageViewController.m
//  HiPDA
//
//  Created by Jiangfan on 2018/9/15.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPSubManageViewController.h"
#import "HPApiSubByUser.h"
#import "HPApiSubByKeyword.h"
#import "HPApi.h"
#import "SVProgressHUD.h"
#import <BlocksKit/NSArray+BlocksKit.h>

@interface HPSubManageViewController ()

// view
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

// data
@property (nonatomic, strong) NSArray<HPApiSubByKeyword *> *subByKeywordList;
@property (nonatomic, strong) NSArray<HPApiSubByUser *> *subByUserList;

@end

@implementation HPSubManageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"订阅管理";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"关键词", @"用户"]];
    self.segmentedControl = segmentedControl;
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(segmentedControlDidUpdate:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
    
    UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(didTapAddSubButton:)];
    self.navigationItem.rightBarButtonItem = addButtonItem;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"HPSubManageListCell"];
    
    [self loadData];
}

- (void)loadData
{
    [SVProgressHUD show];
    
    FBLPromise *p1 = [[HPApi instance] request:@"/sub/list"
                                        params:@{@"type": @0}
                                 modelsOfClass:HPApiSubByKeyword.class];
    
    FBLPromise *p2 = [[HPApi instance] request:@"/sub/list"
                                        params:@{@"type": @1}
                                 modelsOfClass:HPApiSubByUser.class];
    
    @weakify(self);
    [FBLPromise all:@[p1, p2]]
    .then(^id(NSArray<HPApiPage *> *results) {
        @strongify(self);
        [SVProgressHUD dismiss];
        self.subByKeywordList = results.firstObject.list;
        self.subByUserList = results.lastObject.list;
        [self.tableView reloadData];
        return nil;
    })
    .catch(^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    });
}

- (void)segmentedControlDidUpdate:(id)sender
{
    [self.tableView reloadData];
}

- (void)didTapAddSubButton:(id)sender
{
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        return self.subByKeywordList.count;
    } else {
        return self.subByUserList.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HPSubManageListCell" forIndexPath:indexPath];
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        cell.textLabel.text = [self.subByKeywordList objectAtIndex:indexPath.row].keyword;
    } else {
        cell.textLabel.text = [self.subByUserList objectAtIndex:indexPath.row].userName;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *params = nil;
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            HPApiSubByKeyword *keyword = self.subByKeywordList[indexPath.row];
            params = @{@"type": @0, @"keyword": keyword.keyword};
        } else {
            HPApiSubByUser *user = self.subByUserList[indexPath.row];
            params = @{@"type": @1, @"userId": @(user.userId)};
        }
     
        [SVProgressHUD show];
        @weakify(self);
        [[HPApi instance] request:@"/sub/remove"
                           params:params]
        .then(^id(id data) {
            @strongify(self);
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                NSMutableArray *list = [self.subByKeywordList mutableCopy];
                [list removeObjectAtIndex:indexPath.row];
                self.subByKeywordList = [list copy];
            } else {
                NSMutableArray *list = [self.subByUserList mutableCopy];
                [list removeObjectAtIndex:indexPath.row];
                self.subByUserList = [list copy];
            }
            [SVProgressHUD showSuccessWithStatus:@"删除成功"];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            return nil;
        })
        .catch(^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        });
    }
}

@end
