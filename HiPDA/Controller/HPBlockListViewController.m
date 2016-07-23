//
//  HPBlockListViewController.m
//  HiPDA
//
//  Created by Jichao Wu on 14-9-14.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPBlockListViewController.h"
#import "HPBlockService.h"
#import <SVProgressHUD.h>
#import "UIAlertView+Blocks.h"
#import "NSError+BlockService.h"

@interface NSString (BlockList)
- (NSArray *)hp_toList;
@end
@implementation NSString (BlockList)
// 空格, 逗号作为分界符号
- (NSArray *)hp_toList;
{
    NSString *text = self;
    text = [text stringByReplacingOccurrencesOfString:@"," withString:@" "];
    text = [text stringByReplacingOccurrencesOfString:@"，" withString:@" "];

    NSArray *list = [text componentsSeparatedByString:@" "];
    
    NSMutableArray *result = [@[] mutableCopy];
    for (NSString *s in list) {
        if (s.length) {
            [result addObject:s];
        }
    }
    return [result copy];
}
@end

@protocol HPBlockListHeaderViewDelegate <NSObject>

@required
- (void)didTapSyncButton:(UIButton *)button;
- (void)didTapExportButton:(UIButton *)button;
- (void)didTapImportButton:(UIButton *)button;

@end

@interface HPBlockListHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UIButton *syncButton;
@property (nonatomic, strong) UIButton *exportButton;
@property (nonatomic, strong) UIButton *importButton;

@property (nonatomic, weak) id<HPBlockListHeaderViewDelegate> delegate;

@end

@implementation HPBlockListHeaderView
- (instancetype)initWithFrame:(CGRect)frame delegate:(id <HPBlockListHeaderViewDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _delegate = delegate;
        
        _syncButton = ({
            UIButton *button = [UIButton new];
            button.layer.cornerRadius = 5;
            button.layer.borderWidth = 1;
            button.layer.borderColor = [UIColor blackColor].CGColor;
            [button setTitle:@"立即同步" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:15];
            [button addTarget:self.delegate action:@selector(didTapSyncButton:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        
        _exportButton = ({
            UIButton *button = [UIButton new];
            button.layer.cornerRadius = 5;
            button.layer.borderWidth = 1;
            button.layer.borderColor = [UIColor blackColor].CGColor;
            [button setTitle:@"导出" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:15];
            [button addTarget:self.delegate action:@selector(didTapExportButton:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        
        _importButton = ({
            UIButton *button = [UIButton new];
            button.layer.cornerRadius = 5;
            button.layer.borderWidth = 1;
            button.layer.borderColor = [UIColor blackColor].CGColor;
            [button setTitle:@"导入" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:15];
            [button addTarget:self.delegate action:@selector(didTapImportButton:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        
        if (IOS8_OR_LATER) {
            [self addSubview:_syncButton];
            [self addSubview:_exportButton];
            [self addSubview:_importButton];
            [_syncButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self).offset(15.f);
                make.centerY.equalTo(self);
            }];
            [_exportButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(_syncButton.mas_right).offset(15.f);
                make.centerY.equalTo(self);
            }];
            [_importButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(_exportButton.mas_right).offset(15.f);
                make.centerY.equalTo(self);
                make.right.equalTo(self).offset(-15);
                make.width.equalTo(_syncButton);
                make.width.equalTo(_exportButton);
            }];
        } else {
            [self addSubview:_exportButton];
            [self addSubview:_importButton];
            [_exportButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self).offset(15.f);
                make.centerY.equalTo(self);
            }];
            [_importButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(_exportButton.mas_right).offset(15.f);
                make.centerY.equalTo(self);
                make.right.equalTo(self).offset(-15);
                make.width.equalTo(_exportButton);
            }];
        }
    }
    return self;
}
@end

@interface HPBlockListViewController ()<HPBlockListHeaderViewDelegate>

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
    
    HPBlockListHeaderView *headerView = [[HPBlockListHeaderView alloc] initWithFrame:CGRectMake(0, 0, 0, 60)
                                                                            delegate:self];
    self.tableView.tableHeaderView = headerView;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blockListDidChange:) name:kHPBlockListDidChange object:nil];
    
    [[HPBlockService shared] updateWithBlock:^(NSError *error) {
        //已经通过通知监听然后刷新tableview了
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"同步失败"
                                                            message:error.hp_localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"好吧"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
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

#pragma mark - actions
- (void)didTapSyncButton:(UIButton *)button
{
    [SVProgressHUD showWithStatus:@"同步中..."];
    [[HPBlockService shared] updateWithBlock:^(NSError *error) {
        if (!error) {
            [SVProgressHUD showSuccessWithStatus:@"同步成功"];
        } else {
            [SVProgressHUD dismiss];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"同步失败"
                                                            message:error.hp_localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"好吧"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)didTapExportButton:(UIButton *)button
{
    NSString *text = [[[HPBlockService shared] blockList] componentsJoinedByString:@","];
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    [pasteBoard setString:text];
    [SVProgressHUD showSuccessWithStatus:@"已复制到剪贴板"];
}

- (void)didTapImportButton:(UIButton *)button
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"导入黑名单"
                                                    message:@"请用逗号分隔"
                                                   delegate:nil
                                          cancelButtonTitle:@"取消"
                                          otherButtonTitles:@"确定", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            UITextField *content = [alertView textFieldAtIndex:0];
            NSString *text = content.text;
            
            NSArray *list = [text hp_toList];
            [[HPBlockService shared] addUsers:list];
            [self.tableView reloadData];
        }
    }];
}
@end
