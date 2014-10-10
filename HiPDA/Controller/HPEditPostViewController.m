//
//  HPEditPostViewController.m
//  HiPDA
//
//  Created by wujichao on 14-6-15.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPEditPostViewController.h"
#import "HPSendPost.h"

#import "HPNewPost.h"
#import "HPThread.h"
#import "HPUser.h"
#import "HPSearch.h"

#import "UIAlertView+Blocks.h"
#import <SVProgressHUD.h>
#import "NSString+Additions.h"
#import "NSString+HTML.h"


@interface HPEditPostViewController ()

@property (nonatomic, strong) HPNewPost* post;
@property (nonatomic, strong) HPThread* thread;
@property (nonatomic, assign) NSInteger page;

@property (nonatomic, strong) NSString *formhash;
@property (nonatomic, strong) HPNewPost* correct_post;
@property (nonatomic, assign) BOOL waitingForToken;

@property (nonatomic, strong) NSMutableDictionary *parameters;

@end

@implementation HPEditPostViewController

- (id)initWithPost:(HPNewPost *)post
        actionType:(ActionType)type
            thread:(HPThread *)thread
              page:(NSInteger)page
          delegate:(id<HPCompositionDoneDelegate>)delegate
{
    
    self = [super init];
    if (self) {
        _post = post;
        self.actionType = type;
        _thread = thread;
        _page = page;
        [self setDelegate:delegate];
        
        // 打印版网页木有这两个关键参数
        if (_thread.formhash)   _formhash = thread.formhash;
        if (post.pid) _correct_post = post;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"编辑";
    
    [SVProgressHUD showWithStatus:@"马上好" maskType:SVProgressHUDMaskTypeBlack];
    
    if (_formhash && _correct_post) {
        NSLog(@"had _formhash %@, _pid %ld", _formhash, _correct_post.pid);
        
        [self loadOriginalPost];
        
    } else {
        [self loadFormhashAndPidWithBlock:^{
            
            [self loadOriginalPost];
            
        }];
    }
}

- (void)loadFormhashAndPidWithBlock:(void(^)())block {
    
    [self.indicator startAnimating];
    
    //http://www.hi-pda.com/forum/viewthread.php?tid=1273829&extra=&page=2
    //http://www.hi-pda.com/forum/post.php?action=reply&fid=57&tid=1273829&reppost=23560522&extra=&page=2
    [HPSendPost loadFormhashAndPid:self.actionType
                              post:_post
                               tid:_thread.tid
                              page:_page
                             block:^(NSString *formhash, HPNewPost *correct_post, NSError *error)
     {
         [self.indicator stopAnimating];
         
         NSLog(@"get correct formhash %@, pid %ld", formhash, correct_post.pid);
         
         _formhash = formhash;
         _correct_post = correct_post;
         
         if (_formhash && _correct_post) {
             
             if (block) block();
             
         } else {
             
             [UIAlertView showConfirmationDialogWithTitle:@"出错啦"
                                                  message:[NSString stringWithFormat:@"获取回复token失败(错误信息:%@), 是否重试?", [error localizedDescription]]
                                                  handler:^(UIAlertView *alertView, NSInteger buttonIndex)
              {
                  if (buttonIndex == [alertView cancelButtonIndex]) {
                      ;
                  } else {
                      [self loadFormhashAndPidWithBlock:^{
                          block();
                      }];
                  }
              }];
         }
     }];
}

- (void)loadOriginalPost {
    
    [HPSendPost loadOriginalPostWithFid:_thread.fid tid:_thread.tid pid:_correct_post.pid page:_page block:^(NSDictionary *result, NSError *error) {
        if (!error) {
            [SVProgressHUD dismiss];
            
            _parameters = [NSMutableDictionary dictionaryWithDictionary:result];
            self.contentTextFiled.text = [_parameters objectForKey:@"message"];
            
            NSString *title = [result objectForKey:@"subject"];
            NSLog(@"%@", title);
            if (title && ![title isEqualToString:@""]) {
                self.title = title;
            }
            
        } else {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)send:(id)sender {
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [SVProgressHUD showWithStatus:@"发送中..." maskType:SVProgressHUDMaskTypeBlack];
    
    [_parameters setObject:self.contentTextFiled.text forKey:@"message"];
    
    if ([self.imagesString count]) {
        // add image
        for (NSString *image in self.imagesString) {
            NSString *key = [NSString stringWithFormat:@"attachnew[%@][description]", image];
            [_parameters setObject:@"" forKey:key];
        }
    }
    
    [HPSendPost editPost:_parameters block:^(NSError *error) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        if (error) {
            
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
            
        } else {
            
            //[SVProgressHUD showSuccessWithStatus:@"发送成功"];
            [SVProgressHUD dismiss];
            [self doneWithError:nil];
            
        }
    }];
}


@end

