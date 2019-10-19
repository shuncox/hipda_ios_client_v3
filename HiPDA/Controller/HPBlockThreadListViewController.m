//
//  HPBlockThreadListViewController.m
//  HiPDA
//
//  Created by Jiangfan on 2019/10/19.
//  Copyright © 2019 wujichao. All rights reserved.
//

#import "HPBlockThreadListViewController.h"
#import "HPBlockThreadService.h"

@interface HPBlockThreadListViewController ()

@end

@implementation HPBlockThreadListViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (NSArray *)list
{
    return [[HPBlockThreadService shared] blockList];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"不感兴趣的帖子";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"HPBlockThreadListCell"];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
    if (self.list.count == 0) {
       UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                     message:@"在帖子列表中长按帖子, 选择「不感兴趣」, 可以将帖子暂时屏蔽"
                                    delegate:nil
                           cancelButtonTitle:nil
                           otherButtonTitles:@"确定", nil];
       [alertView show];
    }
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HPBlockThreadListCell" forIndexPath:indexPath];
    HPBlockThread *thread = [self.list objectAtIndex:indexPath.row];
    cell.textLabel.text = thread.title;
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
        HPBlockThread *thread = [self.list objectAtIndex:indexPath.row];
        [[HPBlockThreadService shared] removeThread:thread.tid];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)blockListDidChange:(NSNotification *)note
{
    [self.tableView reloadData];
}

@end
