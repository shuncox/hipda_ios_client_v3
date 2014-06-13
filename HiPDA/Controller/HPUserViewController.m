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

@interface HPUserViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) HPUser *user;

@end

@implementation HPUserViewController

- (void)loadView {
    [super loadView];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
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
    [HPUser getUserSpaceDetailsWithUid:_uid orUsername:_username block:^(NSDictionary *dict, NSError *error) {
        
        [HPIndecator dismiss];
        if (!error) {
            
            _data = [dict objectForKey:@"list"];
            _user = [[HPUser alloc] initWithAttributes:dict];
            
            [self.tableView reloadData];
            
        } else {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
    }];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data ? 6:0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section % 2 == 0) {
        return 0;
    } else {
        switch (section) {
            case 1:
                return _data ? 1 : 0;
                break;
            case 3:
                return _data ? 2 : 0;
                break;
            case 5:
                return _data.count;
                break;
            default:
                return 0;
                break;
        }
    }
}

//http://stackoverflow.com/questions/664781/change-default-scrolling-behavior-of-uitableview-section-header
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section % 2 == 0) {
        return @" ";
    }else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 0) {
        
        static UITableViewCell *cell0 = nil;
        if (!cell0) {
            cell0 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"user_cell0"];
        }
        
        [cell0.imageView setImageWithURL:_user.avatarImageURL placeholderImage:nil options:SDWebImageLowPriority];
        cell0.textLabel.text = _user.username;
        cell0.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell0;
        
    } else if (indexPath.section == 3 && indexPath.row == 0) {
        
        static UITableViewCell *cell1 = nil;
        if (!cell1) {
            cell1 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"user_cell1"];
        }
        
        
        cell1.textLabel.text = @"搜索帖子";
        cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        
        return cell1;
        
    } else if (indexPath.section == 3 && indexPath.row == 1) {
        
        static UITableViewCell *cell2 = nil;
        if (!cell2) {
            cell2 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"user_cell2"];
        }
        
        cell2.textLabel.text = @"发短消息";
        cell2.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell2;
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
    
    if (indexPath.section == 3 && indexPath.row == 0) {
        
        HPSearchViewController *searchVC = [[HPSearchViewController alloc] initWithUser:_user];
        [self.navigationController pushViewController:searchVC animated:YES];
        
    } else if (indexPath.section == 3 && indexPath.row == 1) {
        
        [self promptForSendMessage:_user.username];
        
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
