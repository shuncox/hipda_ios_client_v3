//
//  HPFavoriteViewController.m
//  HiPDA
//
//  Created by wujichao on 13-11-22.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPThread.h"
#import "HPUser.h"
#import "HPFavorite.h"
#import "HPFavoriteViewController.h"
#import "HPReadViewController.h"

#import "UIAlertView+Blocks.h"
#import <SVProgressHUD.h>

#import "SWRevealViewController.h"
#import "UIScrollView+SVInfiniteScrolling.h"
#import "UITableView+ScrollToTop.h"

@interface HPFavoriteViewController ()

@property (nonatomic, assign) NSInteger viewAppearCount;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, readonly, strong) NSMutableArray *favoritedThreads;

@end

@implementation HPFavoriteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"收藏";
    self.currentPage = 1;
    
    // ayscn btn
    UIBarButtonItem *ayscnButtonItem = [
                                        [UIBarButtonItem alloc] initWithTitle:@"同步"
                                        style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(confirm:)];
    self.navigationItem.rightBarButtonItems = @[ayscnButtonItem, self.editButtonItem];
    
    [self addRevealActionBI];
    
    if (![self.favoritedThreads count]) {
        [self confirm:nil];
    }
    
    @weakify(self);
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        @strongify(self);
        [self loadMore];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self addGuesture];
    [super viewWillAppear:animated];

    self.viewAppearCount++;
    if (self.viewAppearCount != 1) {
         [self refresh:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self removeGuesture];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - 

- (NSMutableArray *)favoritedThreads
{
    return [[HPFavorite sharedFavorite] favorites];
}


#pragma mark -

- (void)refresh:(id)sender {
    [self.tableView reloadData];
}

- (void)setup {
    
}


- (void)confirm:(id)sender {
    [UIAlertView showConfirmationDialogWithTitle:@"同步"
                                         message:@"您确定同步与HiPDA论坛的收藏吗?"
                                         handler:^(UIAlertView *alertView, NSInteger buttonIndex)
     {
         if (buttonIndex == [alertView cancelButtonIndex]) {
             ;
         } else {
             [self ayscn:nil];
         }
     }];
}

- (void)ayscn:(id)sender {
    
    [SVProgressHUD showWithStatus:@"同步中..."];
    
    [[HPFavorite sharedFavorite] favoriteThreads:@[]];
    [self.tableView reloadData];
    
    [HPFavorite ayscnFavoritesWithPage:1 block:^(NSArray *threads, NSError *error)
     {
         if (error) {
             [SVProgressHUD dismiss];
             [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
             
         } else if ([threads count]){
             [SVProgressHUD dismiss];
             
             [[HPFavorite sharedFavorite] favoriteThreads:threads];
             [self.tableView reloadData];
             [self.tableView hp_scrollToTop];
             [self.tableView flashScrollIndicators];
             
         } else {
             [SVProgressHUD showErrorWithStatus:@"您没有收藏条目"];
         }
     }];
}

- (void)loadMore
{
    @weakify(self);
    [HPFavorite ayscnFavoritesWithPage:self.currentPage+1 block:^(NSArray *threads, NSError *error)
     {
         @strongify(self);
         [self.tableView.infiniteScrollingView stopAnimating];
         if (!error) {
             
             self.currentPage++;
             NSMutableArray *t = [NSMutableArray arrayWithArray:[[HPFavorite sharedFavorite] favorites]];
             [t addObjectsFromArray:threads];
             
             [[HPFavorite sharedFavorite] favoriteThreads:t];
             [self.tableView reloadData];
             
         } else {
             [SVProgressHUD showErrorWithStatus:error.localizedDescription];
         }
     }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.favoritedThreads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HPFavoriteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    HPThread *thread = [self.favoritedThreads objectAtIndex:indexPath.row];
    cell.textLabel.text = thread.title;
    
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
        
        [[HPFavorite sharedFavorite] removeFavoritesAtIndex:indexPath.row block:^(NSString *msg, NSError *error) {
            if(!error) {
                [SVProgressHUD showSuccessWithStatus:@"删除成功"];
            } else {
                [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
            }
        }];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HPThread *thread = [self.favoritedThreads objectAtIndex:indexPath.row];
    HPReadViewController *readVC = [[HPReadViewController alloc] initWithThread:thread];
    
    [self.navigationController pushViewController:readVC animated:YES];
}



@end
