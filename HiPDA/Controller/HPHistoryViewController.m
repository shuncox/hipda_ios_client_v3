//
//  HPHistoryViewController.m
//  HiPDA
//
//  Created by Jichao Wu on 15/2/27.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import "HPHistoryViewController.h"

#import "HPThread.h"
#import "HPUser.h"
#import "HPCache.h"
#import "HPTheme.h"
#import "HPSetting.h"
#import "HPPostViewController.h"

#import <SVProgressHUD.h>
#import "UIAlertView+Blocks.h"



@interface HPHistoryViewController () <UIActionSheetDelegate>

@property (nonatomic, strong)NSMutableArray *histotyList;

@end

@implementation HPHistoryViewController

+ (HPHistoryViewController *)sharedHistoryViewController {
    static HPHistoryViewController *sharedHistoryViewController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHistoryViewController = [[HPHistoryViewController alloc] init];
    });
    return sharedHistoryViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"历史";
    
    [self addRevealActionBI];
    
    // clear btn
    UIBarButtonItem *clearButtonItem = [
                                        [UIBarButtonItem alloc] initWithTitle:@"清除"
                                        style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(clear:)];
    self.navigationItem.rightBarButtonItems = @[clearButtonItem, self.editButtonItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self addGuesture];
    
    // triger reload data
    [self.tableView reloadData];
    
    NSLog(@"_cachedThreads %@", self.histotyList);
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self removeGuesture];
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)setup {
    self.histotyList = [[HPCache sharedCache] history];
    NSLog(@"histotyList %@",self.histotyList);
}


- (void)clear:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self cancelButtonTitle:@"取消"
                                  destructiveButtonTitle:@"清除所有"
                                  otherButtonTitles:nil, nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[HPCache sharedCache] clearHistoty];
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.histotyList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HPHistoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    HPThread *thread = [self.histotyList objectAtIndex:indexPath.row];
    cell.textLabel.text = thread.title;
    cell.textLabel.textColor = [HPTheme textColor];
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [[HPCache sharedCache] removeHistotyAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HPThread *thread = [self.histotyList objectAtIndex:indexPath.row];
    UIViewController *rvc = [[PostViewControllerClass() alloc] initWithThread:thread];
    
    [self.navigationController pushViewController:rvc animated:YES];
}

#pragma mark - theme
- (void)themeDidChanged {
    [self.tableView reloadData];
    [self.tableView setBackgroundColor:[HPTheme backgroundColor]];
}
@end
