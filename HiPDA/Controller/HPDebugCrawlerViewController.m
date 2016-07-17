//
//  HPDebugCrawlerViewController.m
//  HiPDA
//
//  Created by Jichao Wu on 15/10/29.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "HPDebugCrawlerViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "UIAlertView+Blocks.h"
#import "HPSetting.h"
#import "HPHttpClient.h"
#import "HPThread.h"

@interface HPDebugCrawlerViewController ()<MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) BOOL isViewSourceCode;
@property (nonatomic, strong) UIView *actionsView;

// 临时加的
@property (nonatomic, assign) BOOL flag1; //用户主动打开xhr

@end

@implementation HPDebugCrawlerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"诊断问题";
    
    self.actionsView = [UIView new];
    self.actionsView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.actionsView];
    [self.actionsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self.view);
        make.height.equalTo(self.view).multipliedBy(0.25);
    }];
    
    UILabel *tip = [UILabel new];
    tip.font = [UIFont systemFontOfSize:16.f];
    tip.textColor = [UIColor blackColor];
    tip.numberOfLines = 0;
    [self.actionsView addSubview:tip];
    [tip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tip.superview).offset(25.f);
        make.right.equalTo(tip.superview).offset(-25.f);
        make.top.equalTo(tip.superview).offset(25.f);
    }];
    //「」和『』）的使用对于中文字
    tip.text = @"若页面上有「流量工具栏」或「广告」, 请尝试找到「设置」按钮, 选择本月关闭\n"
               @"「联通用户」请关注页面最右下角的一个极小的按钮"
               @"若仍然无法解决问题, 请点击「报告问题」";
    
    UIButton *button = [UIButton new];
    button.layer.borderWidth = 1.f;
    button.layer.borderColor = [UIColor redColor].CGColor;
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 20;
    [button setTitle:@"报告问题" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(report) forControlEvents:UIControlEventTouchUpInside];
    [self.actionsView addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40.f);
        make.width.mas_equalTo(100);
        make.bottom.equalTo(button.superview).offset(-25);
        make.centerX.equalTo(button.superview);
    }];
    
    self.webview = [[UIWebView alloc] init];
    [self.view addSubview:self.webview];
    [self.webview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuideBottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.actionsView.mas_top);
    }];
    
    self.textView = [[UITextView alloc] init];
    self.textView.hidden = YES;
    [self.view addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.webview);
    }];
    
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.context.url]]];
    
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithTitle:@"查看源代码"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(viewHTML:)];
    self.navigationItem.rightBarButtonItem = bbi;
    
    
    [self checkKnownIssues];
    [self debug_requset];
}

- (void)checkKnownIssues
{
    // xhr
    if ([self.context.html rangeOfString:@"XMLHttpRequest"].location != NSNotFound
        && ![Setting boolForKey:HPSettingEnableXHR]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"检测到已知劫持"
                                                        message:@"是否开启强力绕过模式"
                                                       delegate:nil
                                              cancelButtonTitle:@"算了"
                                              otherButtonTitles:@"好的", nil];
        @weakify(self);
        [alert showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            @strongify(self);
            if (buttonIndex != alertView.cancelButtonIndex) {
                [Setting saveBool:YES forKey:HPSettingEnableXHR];
                [self.navigationController popViewControllerAnimated:YES];
                self.flag1 = YES;
            }
        }];
    }
}

- (void)debug_requset
{
    // 临时打开xhr, 然后发一个请求, 上报结果
    if (![Setting boolForKey:HPSettingEnableXHR]) {
        [Setting saveBool:YES forKey:HPSettingEnableXHR];
        @weakify(self);
        [[HPHttpClient sharedClient] getPathContent:self.context.url parameters:nil success:^(AFHTTPRequestOperation *operation, NSString *html) {
            @strongify(self);
            NSArray *threadsInfo = [HPThread extractThreads:html stickthread:NO];
            [Flurry logEvent:@"Test_XHR" withParameters:@{@"url":self.context.url,
                                                          @"count":@(threadsInfo.count),
                                                          @"yes": @(threadsInfo.count > 0)}];
            
            if (!self.flag1) [Setting saveBool:NO forKey:HPSettingEnableXHR];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            @strongify(self);
            if (!self.flag1) [Setting saveBool:NO forKey:HPSettingEnableXHR];
        }];
    }
}

- (void)report
{
#define VERSION ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"])
#define BUILD ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"])
    
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setToRecipients:@[@"wujichao+hpclient@gmail.com"]];
    [controller setSubject:@"HP论坛客户端报告问题"];
    [controller setMessageBody:[NSString stringWithFormat:
                                @"请输入您的网络环境:_________\n"
                                @"请输入您的问题描述:_________\n"
                                @"\n\n\n"
                                @"=========调试信息========\n"
                                @"客户端版本: %@/%@\n"
                                @"请求地址:%@\n"
                                @"请求头:\n%@\n"
                                @"请求Cookies:\n%@\n"
                                @"响应头:\n%@\n"
                                @"响应原文:\n%@\n",
                                VERSION, BUILD,
                                self.context.url,
                                self.context.requestHeaders,
                                self.context.cookies,
                                self.context.responseHeaders,
                                self.context.html] isHTML:NO];
   
    if (controller) [self presentViewController:controller animated:YES completion:NULL];
}

- (void)viewHTML:(UIBarButtonItem *)bbi
{
    self.isViewSourceCode = !self.isViewSourceCode;
    
    self.webview.hidden = self.isViewSourceCode;
    
    self.textView.hidden = !self.isViewSourceCode;
    self.textView.text = self.context.html;
    
    bbi.title = self.isViewSourceCode ? @"查看网页" : @"查看源代码";
}

#pragma mark mail delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    [controller dismissViewControllerAnimated:YES completion:NULL];
}
@end
