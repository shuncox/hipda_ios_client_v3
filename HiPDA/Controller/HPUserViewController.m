//
//  HPUserViewController.m
//  HiPDA
//
//  Created by wujichao on 14-6-12.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPUserViewController.h"
#import "HPUser.h"
#import <SVProgressHUD.h>
#import "HPIndecator.h"
#import <UIImageView+WebCache.h>
#import "HPSearchViewController.h"
#import "UIAlertView+Blocks.h"
#import "HPMessage.h"
#import "HPSetting.h"

@interface HPUserViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) HPUser *user;

@property (nonatomic, strong) UITableViewCell *cell0;
@property (nonatomic, strong) UITableViewCell *cell1;
@property (nonatomic, strong) UITableViewCell *cell2;
@property (nonatomic, strong) UITableViewCell *cell3;

@end

@implementation HPUserViewController

- (void)loadView {
    [super loadView];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.view addSubview:_tableView];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"TableViewSectionHeaderViewIdentifier"];
    
    self.title = @"个人资料";
    
    [self loadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadData {
    
    [HPIndecator show];
    __weak typeof(self) weakSelf = self;
    [HPUser getUserSpaceDetailsWithUid:_uid orUsername:_username block:^(NSDictionary *dict, NSError *error) {
        
        [HPIndecator dismiss];
        if (!error) {
            
            _data = [dict objectForKey:@"list"];
            _user = [[HPUser alloc] initWithAttributes:dict];
            
            [weakSelf.tableView reloadData];
            
        } else {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
    }];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            return 2;
            break;
        case 2:
            return _data ? _data.count : 10;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        if (!_cell0) {
            _cell0 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"user_cell0"];
        }
        
        [_cell0.imageView setImageWithURL:_user.avatarImageURL placeholderImage:nil options:SDWebImageLowPriority];
        _cell0.textLabel.text = _user.username;
        _cell0.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return _cell0;
        
    } if (indexPath.section == 0 && indexPath.row == 1) {
        
        if (!_cell3) {
            _cell3 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"user_cell3"];
        }
        
        _cell3.textLabel.text =
            ([Setting isBlocked:_user.username]?@"取消屏蔽":@"屏蔽此人");
        
        return _cell3;
        
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        
        if (!_cell1) {
            _cell1 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"user_cell1"];
        }
        
        if (_data) {
            _cell1.textLabel.text = @"搜索帖子";
            _cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        return _cell1;
        
    } else if (indexPath.section == 1 && indexPath.row == 1) {
        
        if (!_cell2) {
            _cell2 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"user_cell2"];
        }
        
        if (_data) {
            _cell2.textLabel.text = _data? @"发短消息":nil;
            _cell2.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        return _cell2;
    }
    
    
    static NSString *CellIdentifier = @"HPUserInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [[_data objectAtIndex:indexPath.row] objectForKey:@"key"];
    id value = [[_data objectAtIndex:indexPath.row] objectForKey:@"value"];
    cell.detailTextLabel.text = (value == [NSNull null] ? nil : value);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (!_data) return;
    
    if (indexPath.section == 1
        && indexPath.row == 0) {
        
        HPSearchViewController *searchVC = [[HPSearchViewController alloc] initWithUser:_user];
        [self.navigationController pushViewController:searchVC animated:YES];
        
    } else if (indexPath.section == 1 && indexPath.row == 1) {
        
        [self promptForSendMessage:_user.username];
        
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        
        if ([Setting isBlocked:_user.username]) {
            [Setting removeBlockWithUsername:_user.username];
        } else {
            [Setting addBlockWithUsername:_user.username];
        }
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
    } else {
        ;
    }
}


#pragma mark - send message

- (void)promptForSendMessage:(NSString *)username {
    NSString *title = [NSString stringWithFormat:@"收件人: %@", username];
    [UIAlertView showSendMessageDialogWithTitle:title handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
        if (buttonIndex != [alertView cancelButtonIndex]) {
            
            UITextField *content = [alertView textFieldAtIndex:0];
            NSString *message = content.text;
            [self sendMessageTo:username message:message];
        }
    }];
}

- (void)sendMessageTo:(NSString *)username
              message:(NSString *)message {
    
    if (!message || [message isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"消息内容不能为空"];
        return;
    }
    
    [SVProgressHUD showWithStatus:@"发送中..."];
    [HPMessage sendMessageWithUsername:username message:message block:^(NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        } else {
            [SVProgressHUD showSuccessWithStatus:@"已送达"];
        }
    }];
}



@end
