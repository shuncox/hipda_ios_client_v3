//
//  HPBlockListViewController.m
//  HiPDA
//
//  Created by Jichao Wu on 14-9-14.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPBlockListViewController.h"
#import "HPBlockService.h"

@interface HPBlockListViewController ()

@end

@implementation HPBlockListViewController

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
    return [[HPBlockService shared] blockList];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"屏蔽列表";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"HPBlockListCell"];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if (self.list.count <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"您没有屏蔽过任何人" message:@"您可在查看某个用户资料时屏蔽该用户" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"知道了", nil] show];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blockListDidChange:) name:kHPBlockListDidChange object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HPBlockListCell" forIndexPath:indexPath];
    cell.textLabel.text = [self.list objectAtIndex:indexPath.row];
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
        [[HPBlockService shared] removeUser:[self.list objectAtIndex:indexPath.row]];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)blockListDidChange:(NSNotification *)note
{
    [self.tableView reloadData];
}

@end
