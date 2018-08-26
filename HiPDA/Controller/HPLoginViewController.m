//
//  HPLoginViewController.m
//  HiPDA
//
//  Created by wujichao on 13-11-21.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPLoginViewController.h"
#import "HPThreadViewController.h"
#import "HPRegisterViewController.h"
#import "HPRearViewController.h"

#import "HPAccount.h"
#import "HPSetting.h"

#import "HPAccountPassword.h"
#import "NSUserDefaults+Convenience.h"
#import "RETableViewManager.h"
#import "RETableViewOptionsController.h"
#import <SVProgressHUD.h>
#import "SWRevealViewController.h"
#import "UIAlertView+Blocks.h"
#import "DZWebBrowser.h"
#import "HPAppDelegate.h"
#import <1PasswordExtension/OnePasswordExtension.h>
#import "HPBackgroundFetchService.h"

@interface HPLoginViewController ()

@property (strong, nonatomic) RETableViewManager *manager;
@property (strong, nonatomic) RETableViewSection *section;

@property (strong, nonatomic) RETextItem *usernameItem;
@property (strong, nonatomic) RETextItem *passwordItem;

@property (strong, nonatomic) RERadioItem *secureQuestionItem;
@property (strong, nonatomic) RETextItem *secureAnswerItem;

@property (strong, nonatomic) RETableViewItem *LoginBtnItem;

@end

@implementation HPLoginViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Page LoginVC"];
    self.title = NSLocalizedString(@"HiPDA论坛登陆", nil);
    
    
    UIBarButtonItem *loginButtonItem = [
                                         [UIBarButtonItem alloc] initWithTitle:@"注册"
                                         style:UIBarButtonItemStylePlain
                                        target:self action:@selector(zhuce:)];
    //self.navigationItem.rightBarButtonItem = loginButtonItem;
    
    [self.navigationItem setHidesBackButton:YES animated:NO];
    
    /*
    UIBarButtonItem *guestButtonItem = [
                                        [UIBarButtonItem alloc] initWithTitle:@"随便看看"
                                        style:UIBarButtonItemStylePlain
                                        target:self action:@selector(guest:)];
    self.navigationItem.leftBarButtonItem = guestButtonItem;
    */
    
    // Create manager
    //
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView delegate:self];
    
    
    self.section = [RETableViewSection sectionWithHeaderTitle:@""];
    
    __typeof (&*self) __weak weakSelf = self;
    
    self.usernameItem = [RETextItem itemWithTitle:@"用户名" value:nil placeholder:@"username"];
    self.usernameItem.autocorrectionType = UITextAutocapitalizationTypeNone;
    self.usernameItem.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameItem.spellCheckingType = UITextSpellCheckingTypeNo;
 
    self.passwordItem = [RETextItem itemWithTitle:@"密码" value:nil placeholder:@"******"];
    self.passwordItem.secureTextEntry = YES;
    self.passwordItem.accessoryView = ({
        UIButton *b = [UIButton new];
        b.hidden = ![[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
        [b setImage:[UIImage imageNamed:@"onepassword-button"] forState:UIControlStateNormal];
        [b sizeToFit];
        [b addTarget:self action:@selector(findLoginFrom1Password:) forControlEvents:UIControlEventTouchUpInside];
        b;
    });
    
    self.secureQuestionItem = [RERadioItem itemWithTitle:@"安全提问" value:@"无" selectionHandler:^(RERadioItem *item) {
        [item deselectRowAnimated:YES]; // same as [weakSelf.tableView deselectRowAtIndexPath:item.indexPath animated:YES];
        
        NSArray *options = @[@"0_安全提问", @"1_母亲的名字", @"2_爷爷的名字", @"3_父亲出生的城市", @"4_您其中一位老师的名字", @"5_您个人计算机的型号", @"6_您最喜欢的餐馆名称", @"7_驾驶执照后四位数字"];
        
        // Present options controller
        //
        RETableViewOptionsController *optionsController = [[RETableViewOptionsController alloc] initWithItem:item options:options multipleChoice:NO completionHandler:^(RETableViewItem *i) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
            
            [item reloadRowWithAnimation:UITableViewRowAnimationNone]; // same as [weakSelf.tableView reloadRowsAtIndexPaths:@[item.indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
        
        // Adjust styles
        //
        optionsController.delegate = weakSelf;
        optionsController.style = weakSelf.section.style;
        if (weakSelf.tableView.backgroundView == nil) {
            optionsController.tableView.backgroundColor = weakSelf.tableView.backgroundColor;
            optionsController.tableView.backgroundView = nil;
        }
        
        // Push the options controller
        //
        [weakSelf.navigationController pushViewController:optionsController animated:YES];
    }];
    
    self.secureAnswerItem = [RETextItem itemWithTitle:@"答案" value:nil placeholder:@"留空"];
    self.secureAnswerItem.autocorrectionType = UITextAutocapitalizationTypeNone;
    self.secureAnswerItem.autocorrectionType = UITextAutocorrectionTypeNo;
    self.secureAnswerItem.spellCheckingType = UITextSpellCheckingTypeNo;
    
    self.LoginBtnItem = [RETableViewItem itemWithTitle:@"确定" accessoryType:UITableViewCellAccessoryNone selectionHandler:^(RETableViewItem *item) {
        
        // 先登出前一个账号
        [[HPAccount sharedHPAccount] logout];
        
        item.title = @"登陆中...";
        [item reloadRowWithAnimation:UITableViewRowAnimationAutomatic];
        
        NSString *username = weakSelf.usernameItem.value;
        NSString *password = weakSelf.passwordItem.value;
        
        NSString *questionidString = weakSelf.secureQuestionItem.value;
        NSString *answer = weakSelf.secureAnswerItem.value;
        
        if (!(username && password)) {
            item.title = @"确定";
            [item reloadRowWithAnimation:UITableViewRowAnimationAutomatic];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:@"请填写用户名和密码" delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            return;
        }
        
        NSString *questionid = @"";
        if (![questionidString isEqualToString:@"安全提问"]) {
            questionid = [questionidString substringToIndex:1];
        }
        
        if (!answer) answer = @"";
        
        // 保存用户名
        NSDictionary *profileDict = @{kHPAccountUserName:username};
        NSLog(@"%@", profileDict);
        [NSStandardUserDefaults addObjectsAndKeysFromDictionary:profileDict];
        
        // 保存密码
        HPAccountCredential *credential = [[HPAccountCredential alloc] initWithPassword:password questionid:questionid answer:answer];
        [HPAccountPassword setCredentialFor:username
                                 credential:credential];
        
        // 登录
        if ([NSStandardUserDefaults hasValueForKey:kHPAccountUserName]) {
            [SVProgressHUD showWithStatus:@"登录..." maskType:SVProgressHUDMaskTypeBlack];
            
            [[HPAccount sharedHPAccount] loginWithBlock:^(BOOL isLogin, NSError *error)
             {
                 [weakSelf.view endEditing:YES];
                 item.title = @"确定";
                 [item reloadRowWithAnimation:UITableViewRowAnimationAutomatic];
                 
                 if (isLogin) {
                     [SVProgressHUD dismiss];
                     [weakSelf dismissViewControllerAnimated:YES
                                              completion:
                      ^{
                          [Flurry logEvent:@"Account Login" withParameters:@{@"userid":username}];
                          [Setting loadSetting];
                          [Flurry trackUserIfNeeded];
                          if ([HPAccount isAccountForReviewer]) {
                              [[HPRearViewController sharedRearVC] updateForReviewer];
                          } else {
                              [HPRearViewController threadVCRefresh];
                          }
                          
                          [[HPBackgroundFetchService instance] setupBgFetch];
                      }];
                     
                 } else {
                     [SVProgressHUD dismiss];
                     NSLog(@"%@", [error localizedDescription]);
                     [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                     [[HPAccount sharedHPAccount] logout];
                 }
             }];
        }
    }];
    self.LoginBtnItem.textAlignment = NSTextAlignmentCenter;
    
    [_section addItem:self.usernameItem];
    [_section addItem:self.passwordItem];
    [_section addItem:self.secureQuestionItem];
    [_section addItem:self.secureAnswerItem];
    [_section addItem:self.LoginBtnItem];
    
    [self.manager addSection:_section];
}


- (void)findLoginFrom1Password:(id)sender {
    [[OnePasswordExtension sharedExtension] findLoginForURLString:@"https://www.hi-pda.com" forViewController:self sender:sender completion:^(NSDictionary *loginDictionary, NSError *error) {
        if (loginDictionary.count == 0) {
            if (error.code != AppExtensionErrorCodeCancelledByUser) {
                NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
            }
            return;
        }
        
        self.usernameItem.value = loginDictionary[AppExtensionUsernameKey];
        self.passwordItem.value = loginDictionary[AppExtensionPasswordKey];
        [self.tableView reloadData];
    }];
}

- (void)zhuce:(id)sender {
    
    [Flurry logEvent:@"Account SignUp"];

    NSURL *url = [NSURL URLWithString:S(@"%@/forum/tobenew.php", HP_BASE_URL)];
    [[UIApplication sharedApplication] openURL:url];
    
    /*
     NSURL *url = [NSURL URLWithString:@"http://www.hi-pda.com/forum/register.php"];
     DZWebBrowser *webBrowser = [[DZWebBrowser alloc] initWebBrowserWithURL:url];
     webBrowser.showProgress = YES;
     webBrowser.allowSharing = YES;
     //    webBrowser.resourceBundleName = @"custom-controls";
     
     UINavigationController *webBrowserNC = [[UINavigationController alloc] initWithRootViewController:webBrowser];
     
     [self presentViewController:webBrowserNC animated:YES completion:NULL];
     */
    
    /*
    HPRegisterViewController *rvc = [[HPRegisterViewController alloc]init];
    [self.navigationController pushViewController:rvc animated:YES];
     */
}

/*
- (void)guest:(id)sender {
   
    NSString *username = @"hpclient";
    NSString *password = @"xxxxxxx";
    NSString *answer = @"";
    NSString *questionid = @"";
    
    
    NSDictionary *profileDict = @{kHPAccountUserName:username,
                                  kHPAccountPassword:password,
                                  kHPAccountQuestionid:questionid,
                                  kHPAccountAnswer:answer};
    
    [NSStandardUserDefaults addObjectsAndKeysFromDictionary:profileDict];
    
    if ([NSStandardUserDefaults hasValueForKey:kHPAccountUserName]) {
        [SVProgressHUD showWithStatus:@"加载中..."];
        [[HPAccount sharedHPAccount] loginWithBlock:^(BOOL isLogin, NSError *error)
         {
             if (isLogin) {
                 
                 [SVProgressHUD showSuccessWithStatus:@"请稍后..."];
                 
                 if (_tvc) {
                     //_tvc.isGuest = YES;
                     _tvc.current_fid = 50;
                     [_tvc reload:@"Loading..." forceRefresh:YES];
                     
                 } else {
                     
                     SWRevealViewController *revealController = self.revealViewController;
                     HPThreadViewController *frontViewController = [[HPThreadViewController alloc] init];
                     //frontViewController.isGuest = YES;
                     frontViewController.current_fid = 50;
                     UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:frontViewController];
                     [revealController setFrontViewController:navigationController animated:YES];
                 }
                 
                 [self.navigationController popViewControllerAnimated:YES];
                 
             } else {
                 
                 [SVProgressHUD dismiss];
                 NSLog(@"%@", [error localizedDescription]);
                 [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
                 
                 [[HPAccount sharedHPAccount] logout];
             }
         }];
    }
}
*/

@end
