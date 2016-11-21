//
//  HPReplyTopicViewController.m
//  HiPDA
//
//  Created by wujichao on 14-3-5.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPReplyTopicViewController.h"
#import "HPThread.h"
#import "HPUser.h"
#import "HPSearch.h"

#import "UIAlertView+Blocks.h"
#import <SVProgressHUD.h>
#import "NSString+Additions.h"


@interface HPReplyTopicViewController ()

@property (nonatomic, strong)NSString *formhash;
@property (nonatomic, assign)BOOL waitingForToken;

@end

@implementation HPReplyTopicViewController

/*
 required
    tid 
    fid
 */

- (id)initWithThread:(HPThread *)thread delegate:(id<HPCompositionDoneDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _thread = thread;
        self.actionType = ActionTypeNewPost;
        [self setDelegate:delegate];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"回复";
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.contentTextFiled becomeFirstResponder];
    });
    
    [self loadFormhash];
}

- (void)loadFormhash {
    
    [self.indicator startAnimating];

    __weak typeof(self) weakSelf = self;
    [HPSendPost loadParametersWithBlock:^(NSDictionary *parameters, NSError *error) {
         
         [weakSelf.indicator stopAnimating];
         
         _formhash = [parameters objectForKey:@"formhash"];
         
         
         if (_formhash) {
             
             if (_waitingForToken) {
                 _waitingForToken = NO;
                 [weakSelf send:nil];
             }
             
         } else {
            
             [UIAlertView showConfirmationDialogWithTitle:@"出错啦"
                message:[NSString stringWithFormat:@"获取回复token失败(错误信息:%@), 是否重试?", [error localizedDescription]]
                handler:^(UIAlertView *alertView, NSInteger buttonIndex)
              {
                  if (buttonIndex == [alertView cancelButtonIndex]) {
                      ;
                  } else {
                      [weakSelf loadFormhash];
                  }
              }];
         }
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)send:(id)sender {
    
    
    if (!_formhash) {
        [self.view endEditing:YES];
        [SVProgressHUD showWithStatus:@"正在获取回复token, 马上好" maskType:SVProgressHUDMaskTypeBlack];
        _waitingForToken = YES;
        return;
    }
    
    // check
    if ([self.contentTextFiled.text isEqualToString:@""] ||
        [self.contentTextFiled.text isEqualToString:@"content here..."]) {
        [SVProgressHUD showErrorWithStatus:@"请输入内容"];
        return;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.view endEditing:YES];
    [SVProgressHUD showWithStatus:@"发送中..." maskType:SVProgressHUDMaskTypeBlack];
    
    
    HPReplyTopicParams *replyParams = ({
        HPReplyTopicParams *request = [HPReplyTopicParams new];
        request.content = self.contentTextFiled.text;
        request.fid = self.thread.fid;
        request.tid = self.thread.tid;
        request.formhash = self.formhash;
        request.images = self.imagesString;
        request;
    });
    
    __weak typeof(self) weakSelf = self;
    [HPSendPost sendReplyTopic:replyParams
                         block:^(NSString *msg, NSError *error)
    {
         weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
         if (error) {
             
             if ([[error localizedDescription] indexOf:@"您两次发表间隔少于 30 秒"] != -1) {
                 [SVProgressHUD dismiss];
                 [UIAlertView showConfirmationDialogWithTitle:@"太快啦"
                                                      message:@"您两次发表间隔少于 30 秒, 是否开启定时器?"
                                                      handler:^(UIAlertView *alertView, NSInteger buttonIndex)
                  {
                      if (buttonIndex == [alertView cancelButtonIndex]) {
                          return;
                      }
                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(31 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                          [HPSendPost sendReplyTopic:replyParams
                                               block:^(NSString *msg, NSError *error) {
                                                   // 有可能还会发送失败(30s内多个请求排队发送), 不管了...
                                               }];
                      });
                      [SVProgressHUD showSuccessWithStatus:@"已在后台排队中, 30s后帮您发送"];
                      [weakSelf close];
                  }];
             } else {
                 [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
             }
         } else {
             //[SVProgressHUD showSuccessWithStatus:@"发送成功"];
             [SVProgressHUD dismiss];
             [weakSelf doneWithError:nil];
         }
     }];
}

@end
