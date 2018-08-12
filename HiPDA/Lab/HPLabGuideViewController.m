//
//  HPLabGuideViewController.m
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPLabGuideViewController.h"
#import <Masonry/Masonry.h>
#import "HPLabUserService.h"
#import "SVProgressHUD.h"

@interface HPLabGuideViewController()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *logoutButton;
@property (nonatomic, strong) UIButton *debugButton;

@end

@implementation HPLabGuideViewController

// 功能
// 1. 登录 (授权上传cookies, 上传devicetoken)
// 2. 登录 (调用登出接口, 调用token删除接口)
// 3. 请求debug接口

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"收藏";
    [self addRevealActionBI];
  
    self.view.backgroundColor = [UIColor whiteColor];
    
    _textLabel = [UILabel new];
    _textLabel.numberOfLines = 0;
    [self.view addSubview:_textLabel];
    [_textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(self.view);
        make.height.equalTo(@200);
    }];
    
    _loginButton = [UIButton new];
    [_loginButton setTitle:@"login" forState:UIControlStateNormal];
    [_loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_loginButton];
    [_loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_textLabel.mas_bottom);
    }];
    
    _logoutButton = [UIButton new];
    [_logoutButton setTitle:@"logout" forState:UIControlStateNormal];
    [_logoutButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_logoutButton];
    [_logoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_loginButton.mas_bottom);
    }];
    
    _debugButton = [UIButton new];
    [_debugButton setTitle:@"debug" forState:UIControlStateNormal];
    [_debugButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_debugButton addTarget:self action:@selector(debug) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_debugButton];
    [_debugButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_logoutButton.mas_bottom);
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

- (void)login
{
    [[[[HPLabUserService instance] login] then:^id(id value) {
        self.textLabel.text = [HPLabUserService instance].user.description;
        return nil;
    }] catch:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
    }];
}

- (void)logout
{
    [[[[HPLabUserService instance] logout] then:^id(id value) {
        self.textLabel.text = @"";
        return nil;
    }] catch:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
    }];
}

- (void)debug
{
    [[HPLabUserService instance] debug];
}

- (void)refresh:(id)sender
{
    self.textLabel.text = [HPLabUserService instance].user.description;
}

- (void)setup
{
    
}

@end
