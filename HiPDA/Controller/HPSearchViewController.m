//
//  HPSearchViewController.m
//  HiPDA
//
//  Created by wujichao on 13-11-22.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPSearchViewController.h"
#import "HPReadViewController.h"
#import "HPUserViewController.h"
#import "HPSearchUserCell.h"

#import "HPSearch.h"
#import "HPUser.h"
#import "HPDatabase.h"

#import "UIAlertView+Blocks.h"
#import <SVProgressHUD.h>
#import <ReactiveCocoa.h>

#import "SWRevealViewController.h"

#define CELL_CONTENT_WIDTH 320.0f
#define CELL_CONTENT_MARGIN 10.0f

@interface HPSearchViewController ()

@property (nonatomic, strong) NSArray *results;
@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) HPUser *user;

@end

@implementation HPSearchViewController {
@private
    NSInteger _current_page;
    NSInteger _page_count;
    
    UIBarButtonItem *_searchButtonItem;
    UIBarButtonItem *_nextPageButtonItem;
}

- (instancetype)initWithUser:(HPUser *)user {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _user = user;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:HPSearchUserCell.class forCellReuseIdentifier:NSStringFromClass(HPSearchUserCell.class)];
    
    self.title = @"搜索";
    
    // search btn
    _searchButtonItem = [
                         [UIBarButtonItem alloc] initWithTitle:@"搜索"
                         style:UIBarButtonItemStylePlain
                         target:self
                         action:@selector(search:)];
    
    _nextPageButtonItem = [self addPageControlBtn];
    
    self.navigationItem.rightBarButtonItem = _searchButtonItem;
    
    if (!_user) [self addCloseBI];
  
    // search bar
    //
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44)];
    _searchBar.delegate = self;
    
    _searchBar.placeholder=@"keywords";
    dispatch_async(dispatch_get_main_queue(), ^{
        [_searchBar becomeFirstResponder];
    });
    
    _searchBar.showsScopeBar = YES;
    _searchBar.scopeButtonTitles = @[@"标题", @"全文", @"用户"];
    
    _searchBar.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 44 + 40);

    if (!_user) self.tableView.tableHeaderView = _searchBar;
    
    if (_user) {
        [self search:nil];
    }
    
    
    RACSignal *textSignal = [[self rac_signalForSelector:@selector(searchBar:textDidChange:)
                                            fromProtocol:@protocol(UISearchBarDelegate)] map:^id(RACTuple *tuple) {
        return tuple.second;
    }];
    RACSignal *scopeSignal = [[self rac_signalForSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)
                                            fromProtocol:@protocol(UISearchBarDelegate)] map:^id(RACTuple *tuple) {
        UISearchBar *s = tuple[0];
        return s.text;
    }];
    
    @weakify(self);
    [[[[[[textSignal merge:scopeSignal]
        filter:^BOOL(NSString *text) {
        @strongify(self);
        return text.length > 0 && self.searchBar.selectedScopeButtonIndex == HPSearchTypeUser;
    }] throttle:0.3]
       flattenMap:^RACStream *(NSString *key) {
           @strongify(self);
           return [self.class signalForSearchUserWithKey:key];
       }]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSArray *results) {
         @strongify(self);
         
         _results = results;
         _page_count = 1;
         
         [self.tableView reloadData];
         if (_results.count > 0) {
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
             [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
             [self.tableView flashScrollIndicators];
         }
     }];
}

- (void)viewWillAppear:(BOOL)animated {
    
    //[self addGuesture];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - scrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

#pragma mark -

- (void)setup {
    _current_page = 1;
}

- (void)revealToggle:(id)sender {
    [_searchBar resignFirstResponder];
    
    SWRevealViewController *revealController = [self revealViewController];
    [revealController revealToggle:sender];
}


- (void)search:(id)sender {
    
    if (_user) {
        [self searchForUser:sender];
        return;
    }
    
    if (self.searchBar.selectedScopeButtonIndex == HPSearchTypeUser) {
        return;
    }
    
    [_searchBar resignFirstResponder];
    
    // tip
    NSString *tip = NULL;
    if ([sender isKindOfClass:[NSString class]]) {
        tip = (NSString *)sender;
    } else {
        tip = @"搜索中...";
    }
    
    
    // key
    NSString *key = _searchBar.text;
    HPSearchType type = _searchBar.selectedScopeButtonIndex;
    
    if (!key || [key isEqualToString:@""]) {
        
        [SVProgressHUD showErrorWithStatus:@"请输入关键词"];
        [_searchBar becomeFirstResponder];
        return;
    }
    
    NSLog(@"key %@, type : %d", key, type);
    
    
    // update ui
    self.title = [NSString stringWithFormat:@"搜索: %@", key];
    
    
    
    [SVProgressHUD showWithStatus:tip];
    
    //_results = nil;
    //[self.tableView reloadData];
    
    NSDictionary *parameters = @{@"key": key};
    __weak typeof(self) weakSelf = self;
    [HPSearch searchWithParameters:parameters
                              type:type
                              page:_current_page
                             block:^(NSArray *results, NSInteger pageCount, NSError *error) {
                                 
                                 if (error) {
                                     [SVProgressHUD dismiss];
                                     
                                     [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                                     
                                     // update ui
                                     weakSelf.title = @"搜索";
                                     weakSelf.navigationItem.rightBarButtonItem = _searchButtonItem;
                                     
                                 } else if ([results count]){
                                     [SVProgressHUD dismiss];
                                     
                                     _results = results;
                                     _page_count = pageCount;
                                     
                                     [weakSelf.tableView reloadData];
                                     
                                     NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                                     [weakSelf.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
                                     [weakSelf.tableView flashScrollIndicators];
                                     
                                     // update ui
                                     weakSelf.title = [NSString stringWithFormat:@"搜索: %@ (%d/%d)", key, _current_page, _page_count];
                                     weakSelf.navigationItem.rightBarButtonItem = _nextPageButtonItem;
                                     
                                 } else {
                                     //NSLog(@"in");
                                     
                                     [SVProgressHUD showErrorWithStatus:@"对不起，没有找到匹配结果。"];
                                     //NSLog(@"in2");
                                     [_searchBar becomeFirstResponder];
                                     
                                     // update ui
                                     weakSelf.title = @"搜索";
                                     weakSelf.navigationItem.rightBarButtonItem = _searchButtonItem;
                                 }
                             }];
}

- (void)searchForUser:(id)sender {
    
    [SVProgressHUD showWithStatus:@"搜索中..."];
    
    NSDictionary *parameters = @{@"key": S(@"%d",_user.uid)};
    
    __weak typeof(self) weakSelf = self;
    [HPSearch searchWithParameters:parameters
                              type:HPSearchTypeUserTopic
                              page:_current_page
                             block:^(NSArray *results, NSInteger pageCount, NSError *error) {
                                 
                                 if (error) {
                                     
                                     [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                                     
                                 } else if ([results count]){
                                     [SVProgressHUD dismiss];
                                     
                                     _results = results;
                                     _page_count = pageCount;
                                     
                                     [weakSelf.tableView reloadData];
                                     
                                     NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                                     [weakSelf.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
                                     [weakSelf.tableView flashScrollIndicators];
                                     
                                     // update ui
                                     weakSelf.title = [NSString stringWithFormat:@"主题 (%d/%d)", _current_page, _page_count];
                                     weakSelf.navigationItem.rightBarButtonItem = _nextPageButtonItem;
                                     
                                 } else {
                                     
                                     [SVProgressHUD showErrorWithStatus:@"对不起，没有找到匹配结果。"];
                                     
                                 }
                             }];
}

- (void)prevPage:(id)sender {
    
    if (_current_page <= 1) {
        [SVProgressHUD showErrorWithStatus:@"已经是第一页"];
    } else {
        _current_page--;
        [self search:[NSString stringWithFormat:@"前往第%d页...", _current_page]];
    }
}

- (void)nextPage:(id)sender {
    
    //NSLog(@"sender %@", sender);
    
    if (_current_page >= _page_count) {
        [SVProgressHUD showErrorWithStatus:@"已经是最后一页"];
    } else {
        _current_page++;
        [self search:[NSString stringWithFormat:@"前往第%d页...", _current_page]];
    }
}

#pragma mark -  UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    //NSLog(@"searchBar.text %@", searchBar.text);
    [self search:searchBar];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    //NSLog(@"selectedScope %d", selectedScope);
    
    // update ui
    self.title = @"搜索";
    _current_page = 1;
    self.navigationItem.rightBarButtonItem = _searchButtonItem;
    
    if (searchBar.text.length > 0) {
        [self search:searchBar];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // update ui
    self.title = @"搜索";
    self.navigationItem.rightBarButtonItem = _searchButtonItem;
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
    return [_results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HPSearchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont systemFontOfSize:HPSearch_FONT_SIZE];
        //cell.detailTextLabel.numberOfLines = 0;
    }
    
    NSMutableDictionary *dict = [_results objectAtIndex:indexPath.row];
    
    HPSearchType type = _searchBar.selectedScopeButtonIndex;
    
    switch (type) {
        case HPSearchTypeTitle:
        {
            cell.textLabel.attributedText = [dict objectForKey:@"title"];
            
            
            NSString *moreInfo = [NSString stringWithFormat:@"%@  -  %@  -  %@",
                                  [dict objectForKey:@"forum"],
                                  [dict objectForKey:@"username"],
                                  [dict objectForKey:@"dateString"]];
            cell.detailTextLabel.text = moreInfo;
            break;
        }
        case HPSearchTypeFullText:
        {
            cell.textLabel.attributedText = [dict objectForKey:@"detail"];
            
            NSString *moreInfo = [NSString stringWithFormat:@"标题: %@, 作者: %@",
                                  [dict objectForKey:@"title"],
                                  [dict objectForKey:@"username"]];
            cell.detailTextLabel.text = moreInfo;
            break;
        }
        case HPSearchTypeUser:
        {
            HPSearchUserCell *userCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(HPSearchUserCell.class)];
            HPUser *user = [dict objectForKey:@"user"];
            userCell.user = user;
            return userCell;
        }
        default:
            NSLog(@"error HPSearchType %d", type);
            break;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableDictionary *dict = [_results objectAtIndex:indexPath.row];
    UIViewController *vc = nil;
    
    if (self.searchBar.selectedScopeButtonIndex == HPSearchTypeUser) {
        HPUser *user = dict[@"user"];
        HPUserViewController *uvc = [HPUserViewController new];
        uvc.username = user.username;
        uvc.uid = user.uid;
        vc = uvc;
        
    } else {
        HPThread *thread = [HPThread new];
        thread.fid = [[dict objectForKey:@"fidString"] integerValue];
        thread.tid = [[dict objectForKey:@"tidString"] integerValue];
        NSAttributedString *title = [dict objectForKey:@"title"];
        thread.title = [title string];
        NSInteger find_pid = [[dict objectForKey:@"pidString"] integerValue];
        
        vc = [[HPReadViewController alloc] initWithThread:thread find_pid:find_pid];
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableDictionary *dict = [_results objectAtIndex:indexPath.row];
    NSAttributedString *text = nil;
    HPSearchType type = _searchBar.selectedScopeButtonIndex;
    switch (type) {
        case HPSearchTypeTitle:
        {
            text = [dict objectForKey:@"title"];
            break;
        }
        case HPSearchTypeFullText:
        {
            text = [dict objectForKey:@"detail"];
            break;
        }
        case HPSearchTypeUser:
        {
            return 50.f;
            break;
        }
        default:
            NSLog(@"error HPSearchType %d", type);
            break;
    }

    
    CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), 20000.0f);
    
    CGRect rect = [text boundingRectWithSize:constraint
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    CGSize size = rect.size;
    
    //NSLog(@"%f", size.height);
    CGFloat height = MAX(size.height + 20 , 50.0f);
    
    return height + (CELL_CONTENT_MARGIN * 2);
    
    /*

    CGSize sizeToFit = [[dict objectForKey:@"title"] sizeWithFont:[UIFont systemFontOfSize:16.0f] constrainedToSize:CGSizeMake(320.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    
    return fmaxf(70.0f, sizeToFit.height + 40.0f);*/
}


+ (RACSignal *)signalForSearchUserWithKey:(NSString *)key {
    
    static NSOperationQueue *q = nil;
    if (!q) {
        q = [[NSOperationQueue alloc] init];
        [q setMaxConcurrentOperationCount:1];
    }
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSBlockOperation *op = [[NSBlockOperation alloc] init];
        
        [op addExecutionBlock:^{
            
            NSMutableArray *results = [NSMutableArray array];
            [[HPDatabase sharedDb] open];
            
            FMResultSet *resultSet = [[[HPDatabase sharedDb] db] executeQuery:@"SELECT * FROM user WHERE username LIKE ?", [NSString stringWithFormat:@"%%%@%%", key]];
            while ([resultSet next]) {
                
                NSString *username = [resultSet stringForColumnIndex:0];
                NSString *uid = [resultSet stringForColumnIndex:1];
                
                HPUser *user = [HPUser new];
                user.username = username;
                user.uid = [uid integerValue];
                [results addObject:@{@"user": user}];
            }
            
            [[HPDatabase sharedDb] close];
            
            [subscriber sendNext:[results copy]];
            [subscriber sendCompleted];
        }];
        
        [q addOperation:op];
        
        return nil;
    }];
}


@end
