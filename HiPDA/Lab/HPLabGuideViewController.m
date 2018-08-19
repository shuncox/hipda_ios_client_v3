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
#import "HPLabService.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import "UIAlertView+Blocks.h"
#import "HPPushService.h"

@interface HPLabGuideViewController()

@property (nonatomic, strong) UILabel *enableLabLabel;
@property (nonatomic, strong) UISwitch *enableLabSwitch;

@property (nonatomic, strong) UILabel *enablePushLabel;
@property (nonatomic, strong) UISwitch *enablePushSwitch;

@property (nonatomic, strong) UILabel *enableSubLabel;
@property (nonatomic, strong) UISwitch *enableSubSwitch;

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
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _enableLabLabel = [UILabel new];
    _enableLabLabel.text = @"授权cookies";
    [self.view addSubview:_enableLabLabel];
    [_enableLabLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(100.f);
    }];
    
    _enableLabSwitch = [UISwitch new];
    [self.view addSubview:_enableLabSwitch];
    _enableLabSwitch.enabled = NO;
    [_enableLabSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_enableLabLabel.mas_right);
        make.top.equalTo(_enableLabLabel);
    }];
    
    _enablePushLabel = [UILabel new];
    _enablePushLabel.text = @"开启消息推送";
    [self.view addSubview:_enablePushLabel];
    [_enablePushLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_enableLabLabel.mas_bottom).offset(20.f);
    }];
    
    _enablePushSwitch = [UISwitch new];
    [self.view addSubview:_enablePushSwitch];
    [_enablePushSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_enablePushLabel.mas_right);
        make.top.equalTo(_enablePushLabel);
    }];
    
    _enableSubLabel = [UILabel new];
    _enableSubLabel.text = @"开启订阅";
    [self.view addSubview:_enableSubLabel];
    [_enableSubLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_enablePushLabel.mas_bottom).offset(20.f);
    }];
    
    _enableSubSwitch = [UISwitch new];
    [self.view addSubview:_enableSubSwitch];
    [_enableSubSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_enableSubLabel.mas_right);
        make.top.equalTo(_enableSubLabel);
    }];
    
    _textLabel = [UILabel new];
    _textLabel.numberOfLines = 0;
    [self.view addSubview:_textLabel];
    [_textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(200.f);
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
    
    [_enablePushSwitch bk_addEventHandler:^(UISwitch *s) {
        FBLPromise *promise = nil;
        if (s.on) { //开启推送
            promise =
            // 1. 请求上传cookies的权限
            [[HPLabService instance] checkCookiesPermission]
            // 2. 请求推送权限
            .then(^id(NSNumber *grant) {
                if (!grant.boolValue) {
                    return [FBLPromise resolvedWith:@(NO)];
                }
                return [HPPushService checkPushPermission];
            })
            // 3. 调用接口开启推送
            .then(^id(NSNumber/*HPAuthorizationStatus*/ *value) {
                HPAuthorizationStatus status = value.intValue;
                if (status == HPAuthorizationStatusDenied) {
                    return [FBLPromise resolvedWith:@(NO)];
                }
                return [[HPLabService instance] updatePushEnable:YES];
            });
        } else { //关闭推送
            // 调用接口关闭推送
            promise = [[HPLabService instance] updatePushEnable:NO];
        }
        
        promise
        .then(^id(NSNumber *success) {
            if (success.boolValue) {
                [HPLabService instance].enableMessagePush = ![HPLabService instance].enableMessagePush;
            }
            return success;
        })
        .catch(^(NSError *error) {
            s.on = !s.on;
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        });
    } forControlEvents:UIControlEventValueChanged];
    
    [_enableSubSwitch bk_addEventHandler:^(UISwitch *s) {
        [[HPLabService instance] checkCookiesPermission]
        .then(^id(NSNumber *grant) {
            if (grant.boolValue) {
                // TODO 调用接口
                [HPLabService instance].enableSubscribe = s.on;
            } else {
                s.on = !s.on;
            }
            return nil;
        })
        .catch(^(NSError *error) {
            s.on = !s.on;
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        });
    } forControlEvents:UIControlEventValueChanged];
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
    self.enableLabSwitch.on = [HPLabService instance].grantUploadCookies;
    self.enablePushSwitch.on = [HPLabService instance].enableMessagePush;
    self.enableSubSwitch.on = [HPLabService instance].enableSubscribe;
    
    if ([HPLabUserService instance].isLogin) {
        [[HPLabService instance] getPushEnable]
        .then(^id(NSNumber *enable) {
            [HPLabService instance].enableMessagePush = enable.boolValue;
            self.enablePushSwitch.on = [HPLabService instance].enableMessagePush;
            return nil;
        })
        .catch(^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        });
    }
}

- (void)setup
{
    
}


@end
