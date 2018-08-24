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
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>
#import "HPApi.h"
#import "HPApiLabConfig.h"
#import "NSString+Additions.h"

@interface HPLabGuideViewController()

@property (nonatomic, strong) UILabel *enablePushLabel;
@property (nonatomic, strong) UILabel *enablePushDesc;
@property (nonatomic, strong) UISwitch *enablePushSwitch;

@property (nonatomic, strong) UILabel *enableSubLabel;
@property (nonatomic, strong) UILabel *enableSubDesc;
@property (nonatomic, strong) UISwitch *enableSubSwitch;

@property (nonatomic, strong) UIWebView *noticeWebView;

// debug view
@property (nonatomic, strong) UILabel *enableLabLabel;
@property (nonatomic, strong) UISwitch *enableLabSwitch;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *logoutButton;
@property (nonatomic, strong) UIButton *debugButton;

@end

@implementation HPLabGuideViewController

+ (void)presentIn:(UIViewController *)parent
{
    if (!parent) {
        parent = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    }
    HPLabGuideViewController *lab = [HPLabGuideViewController new];
    lab.isModal = YES;
    UIViewController *vc = [HPCommon swipeableNVCWithRootVC:lab];
    [parent presentViewController:vc animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"实验室";
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.isModal) {
        @weakify(self);
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"关闭" style:UIBarButtonItemStylePlain handler:^(id sender) {
            @strongify(self);
            [self close];
        }];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem new];
    }
    
    [self setupViews];
    
#ifdef DEBUG
    [self setupDebugViews];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [self refreshUI];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)setupViews
{
    UIView *pushContainer = [UIView new];
    pushContainer.layer.borderColor = [UIColor blackColor].CGColor;
    pushContainer.layer.borderWidth = 1.f;
    pushContainer.layer.cornerRadius = 20.f;
    [self.view addSubview:pushContainer];
    [pushContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20.f);
        make.right.equalTo(self.view).offset(-20.f);
        make.top.equalTo(self.view).offset(28.f + 64.f);
        make.height.equalTo(@120);
    }];
    
    _enablePushLabel = [UILabel new];
    _enablePushLabel.text = @"实时消息提醒";
    _enablePushLabel.font = [UIFont systemFontOfSize:20];
    _enablePushLabel.textColor = [UIColor blackColor];
    [pushContainer addSubview:_enablePushLabel];
    [_enablePushLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(pushContainer).offset(14.f);
        make.top.equalTo(pushContainer).offset(12.f);
    }];
    
    _enablePushSwitch = [UISwitch new];
    [pushContainer addSubview:_enablePushSwitch];
    [_enablePushSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(pushContainer).offset(-14.f);
        make.centerY.equalTo(_enablePushLabel);
    }];
    
    _enablePushDesc = [UILabel new];
    _enablePushDesc.text = @"提供近乎实时的短消息提醒和帖子消息提醒, 不需要客户端后台运行.\n运行原理: 在应用服务器上使用您的cookies不间断的轮训查看是否有新消息, 然后推送给您.";
    _enablePushDesc.numberOfLines = 0;
    _enablePushDesc.font = [UIFont systemFontOfSize:12];
    _enablePushDesc.textColor = [UIColor blackColor];
    [pushContainer addSubview:_enablePushDesc];
    [_enablePushDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(pushContainer).offset(14.f);
        make.right.equalTo(pushContainer).offset(-14.f);
        make.bottom.equalTo(pushContainer).offset(-12.f);
    }];
    
    
    UIView *subContainer = [UIView new];
    subContainer.layer.borderColor = [UIColor blackColor].CGColor;
    subContainer.layer.borderWidth = 1.f;
    subContainer.layer.cornerRadius = 20.f;
    [self.view addSubview:subContainer];
    [subContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(pushContainer);
        make.top.equalTo(pushContainer.mas_bottom).offset(20);
        make.height.equalTo(@120);
    }];

    _enableSubLabel = [UILabel new];
    _enableSubLabel.text = @"帖子订阅";
    _enableSubLabel.font = [UIFont systemFontOfSize:20];
    _enableSubLabel.textColor = [UIColor blackColor];
    [subContainer addSubview:_enableSubLabel];
    [_enableSubLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(subContainer).offset(14.f);
        make.top.equalTo(subContainer).offset(12.f);
    }];

    _enableSubSwitch = [UISwitch new];
    _enableSubSwitch.hidden = YES;//TODO
    [subContainer addSubview:_enableSubSwitch];
    [_enableSubSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(subContainer).offset(-14.f);
        make.centerY.equalTo(_enableSubLabel);
    }];
    
    // TODO
    UIView *enableSubButton = [UIView new];
    enableSubButton.backgroundColor = [@"#909090" colorFromHexString];
    enableSubButton.layer.cornerRadius = 6.f;
    [subContainer addSubview:enableSubButton];
    [enableSubButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(subContainer).offset(-14.f);
        make.centerY.equalTo(_enableSubLabel);
        make.width.equalTo(@50.f);
        make.height.equalTo(@32.f);
    }];
    UILabel *enableSubButtonLabel = [UILabel new];
    enableSubButtonLabel.text = @"开发中";
    enableSubButtonLabel.font = [UIFont systemFontOfSize:14];
    enableSubButtonLabel.textColor = [UIColor whiteColor];
    [enableSubButton addSubview:enableSubButtonLabel];
    [enableSubButtonLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(enableSubButton);
    }];
    
    _enableSubDesc = [UILabel new];
    _enableSubDesc.text = @"提供关键词订阅和用户名订阅功能, 并且符合条件的帖子会通过推送提醒您.\n运行原理: 在应用服务器上不间断的轮训查看是否有符合您设定条件的新帖, 然后推送给您.";
    _enableSubDesc.numberOfLines = 0;
    _enableSubDesc.font = [UIFont systemFontOfSize:12];
    _enableSubDesc.textColor = [UIColor blackColor];
    [subContainer addSubview:_enableSubDesc];
    [_enableSubDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(subContainer).offset(14.f);
        make.right.equalTo(subContainer).offset(-14.f);
        make.bottom.equalTo(subContainer).offset(-12.f);
    }];
    
    _noticeWebView = [UIWebView new];
    _noticeWebView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_noticeWebView];
    [_noticeWebView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(subContainer.mas_bottom).offset(15.f);
        make.left.right.equalTo(subContainer);
        make.bottom.equalTo(self.view);
    }];
    
    NSError *USER_CANCEL_ERROR = [[NSError alloc] initWithDomain:@"" code:0 userInfo:nil];
    NSError *USER_DENY_PUSH_ERROR = [[NSError alloc] initWithDomain:@"" code:0 userInfo:nil];
    
    [_enablePushSwitch bk_addEventHandler:^(UISwitch *s) {
        FBLPromise *promise = nil;
        if (s.on) { //开启推送
            promise =
            // 1. 请求上传cookies的权限
            [[HPLabService instance] checkCookiesPermission]
            .then(^id(NSNumber *grant) {
                if (!grant.boolValue) {
                    return USER_CANCEL_ERROR;
                }
                return grant;
            })
            // 登录, 而不是自动登录, 防止step2请求推送异步上传token和step3开启push都需要登录
            .then(^id(NSNumber *grant) {
                return [[HPLabUserService instance] loginIfNeeded];
            })
            // 2. 请求推送权限
            .then(^id(NSNumber *grant) {
                return [HPPushService checkPushPermission];
            })
            .then(^id(NSNumber/*HPAuthorizationStatus*/ *value) {
                HPAuthorizationStatus status = value.intValue;
                if (status == HPAuthorizationStatusDenied) {
                    return USER_DENY_PUSH_ERROR;
                }
                return value;
            })
            // 3. 调用接口开启推送
            .then(^id(NSNumber/*HPAuthorizationStatus*/ *value) {
                return [[HPLabService instance] updatePushEnable:YES];
            });
        } else { //关闭推送
            // 调用接口关闭推送
            promise = [[HPLabService instance] updatePushEnable:NO];
        }
        
        promise
        .then(^id(NSNumber *enable) {
            [HPLabService instance].enableMessagePush = enable.boolValue;
            return enable;
        })
        .catch(^(NSError *error) {
            s.on = !s.on;
            if (error == USER_CANCEL_ERROR) { //用户取消授权
                // no-op;
            } else if (error == USER_DENY_PUSH_ERROR) { //用户关闭推送权限
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:@"消息推送需要您打开推送权限"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"取消"
                                                          otherButtonTitles:@"确定", nil];
                [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (buttonIndex != alertView.cancelButtonIndex) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }
                }];
            } else {
                [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
            }
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

- (void)setupDebugViews
{
    UIView *debugView = [UIView new];
    debugView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    [self.view addSubview:debugView];
    [debugView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self.view);
        make.height.equalTo(@150);
    }];
    
    _textLabel = [UILabel new];
    _textLabel.numberOfLines = 0;
    _textLabel.text = @"11";
    _textLabel.font = [UIFont systemFontOfSize:10.f];
    [debugView addSubview:_textLabel];
    [_textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(debugView);
        make.height.equalTo(@80.f);
    }];
    
    _enableLabLabel = [UILabel new];
    _enableLabLabel.text = @"授权cookies";
    _enableLabLabel.textColor = [UIColor blackColor];
    [debugView addSubview:_enableLabLabel];
    [_enableLabLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(debugView);
        make.top.equalTo(_textLabel.mas_bottom).offset(2);
    }];
    
    _enableLabSwitch = [UISwitch new];
    [debugView addSubview:_enableLabSwitch];
    [_enableLabSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_enableLabLabel.mas_right);
        make.centerY.equalTo(_enableLabLabel);
    }];
    
    _loginButton = [UIButton new];
    [_loginButton setTitle:@"login" forState:UIControlStateNormal];
    [_loginButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    [debugView addSubview:_loginButton];
    [_loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_enableLabLabel.mas_bottom).offset(5);
        make.left.equalTo(debugView);
    }];
    
    _logoutButton = [UIButton new];
    [_logoutButton setTitle:@"logout" forState:UIControlStateNormal];
    [_logoutButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    [debugView addSubview:_logoutButton];
    [_logoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_loginButton);
        make.left.equalTo(_loginButton.mas_right).offset(20);
    }];

    _debugButton = [UIButton new];
    [_debugButton setTitle:@"debug" forState:UIControlStateNormal];
    [_debugButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_debugButton addTarget:self action:@selector(debug) forControlEvents:UIControlEventTouchUpInside];
    [debugView addSubview:_debugButton];
    [_debugButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_loginButton);
        make.left.equalTo(_logoutButton.mas_right).offset(20);
    }];

    [_enableLabSwitch bk_addEventHandler:^(UISwitch *s) {
        [HPLabService instance].grantUploadCookies = s.on;
    } forControlEvents:UIControlEventValueChanged];
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

- (void)refreshUI
{
    self.textLabel.text = [HPLabUserService instance].user.description;
    self.enableLabSwitch.on = [HPLabService instance].grantUploadCookies;
    self.enablePushSwitch.on = [HPLabService instance].enableMessagePush;
    self.enableSubSwitch.on = [HPLabService instance].enableSubscribe;
    
    @weakify(self);
    if ([HPLabUserService instance].isLogin) {
        [[HPLabService instance] getPushEnable]
        .then(^id(NSNumber *enable) {
            @strongify(self);
            [HPLabService instance].enableMessagePush = enable.boolValue;
            self.enablePushSwitch.on = [HPLabService instance].enableMessagePush;
            return nil;
        })
        .catch(^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        });
    }
    
    [SVProgressHUD show];
    [[HPLabService instance] getLabConfig]
    .then(^id(HPApiLabConfig *config) {
        @strongify(self);
        [SVProgressHUD dismiss];
        [self handleConfig:config];
        return config;
    })
    .catch(^(NSError *error) {
        @strongify(self);
        [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        [self close];
    });
}

- (void)handleConfig:(HPApiLabConfig *)config
{
    if (config.alert.length) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:config.alert
                                                           delegate:nil
                                                  cancelButtonTitle:@"好的"
                                                  otherButtonTitles:nil];
        [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            [self close];
        }];
        return;
    }
    
    [self.noticeWebView loadHTMLString:config.noticeHtml baseURL:nil];
    
    if (config.disableMessagePush) {
        // TODO
    }
    
    if (config.disableSubscribe) {
        // TODO
    }
}

- (void)close
{
    if (self.isModal) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
/*
// https://stackoverflow.com/questions/23620276/check-if-view-controller-is-presented-modally-or-pushed-on-a-navigation-stack
- (BOOL)isModal
{
    if([self presentingViewController])
        return YES;
    if([[[self navigationController] presentingViewController] presentedViewController] == [self navigationController])
        return YES;
    if([[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
        return YES;
    return NO;
}
*/

@end
