//
//  HPMessageDetailViewController.m
//  HiPDA
//
//  Created by wujichao on 13-12-1.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPMessageDetailViewController.h"
#import <UIImageView+AFNetworking.h>

#import "HPMessage.h"
#import "HPUser.h"

#import <UIImageView+WebCache.h>
#import <SVProgressHUD.h>
#import "NSUserDefaults+Convenience.h"
#import "UIAlertView+Blocks.h"
#import "UIBarButtonItem+ImageItem.h"

@interface HPMessageDetailViewController () <JSMessagesViewDataSource, JSMessagesViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSMutableArray *messages;
@property (nonatomic, assign) HPMessageRange range;

@end


@implementation HPMessageDetailViewController

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];
    
    _range = HPMessageRangeLatest;
    
    self.title = [NSString stringWithFormat:@"与 %@", _user.username];
    [self setBackgroundColor:[UIColor whiteColor]];
    
    //
    //
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    self.messageInputView.textView.placeHolder = NSLocalizedString(@"New Message", nil);
    self.sender = [NSStandardUserDefaults stringForKey:kHPAccountUserName];
    
    /*
    // refresh btn
    UIBarButtonItem *refreshButtonItem = [
                                          [UIBarButtonItem alloc] initWithTitle:@"刷新"
                                          style:UIBarButtonItemStylePlain
                                          target:self
                                          action:@selector(refresh:)];
    self.navigationItem.rightBarButtonItem = refreshButtonItem;
    */
    UIBarButtonItem *moreBI = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"more.png"]
                                                           size:CGSizeMake(40.f, 40.f)
                                                         target:self
                                                         action:@selector(action:)];
    self.navigationItem.rightBarButtonItem = moreBI;
    
    // gesture
    UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(back:)];
    rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipeGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refresh:nil];
}

- (void)dealloc {
    NSLog(@"dealloc");
}

#pragma mark -

- (void)back:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)refresh:(id)sender {
    
    __typeof__(self) __weak weakSelf = self;
    [SVProgressHUD showWithStatus:@"载入中..."];
    [HPMessage loadMessageDetailWithUid:weakSelf.user.uid
                              daterange:weakSelf.range
                                  block:^(NSArray *lists, NSError *error)
     {
         if (error) {
             [SVProgressHUD dismiss];
             [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
             
         } else if ([lists count]){
             [SVProgressHUD dismiss];
             
             weakSelf.messages = [NSMutableArray arrayWithArray:lists];
             [weakSelf.tableView reloadData];
             
             // animate = yes = crash often
             [weakSelf scrollToBottomAnimated:NO];
             
         } else {
             [SVProgressHUD dismiss];
             
             NSString *tip = nil;
             switch (weakSelf.range) {
                 case HPMessageRangeLatest:
                     tip = @"最近三天没有新短消息\n是否查看更早时间的短消息历史？";
                     break;
                 case HPMessageRangeCurrentWeek:
                     tip = @"本周没有新短消息\n是否查看更早时间的短消息历史？";
                     break;
                 case HPMessageRangeAll:
                     tip = @"未找到任何记录\n是否重试？";
                     break;
                 default:
                     break;
             }
             
             [UIAlertView showConfirmationDialogWithTitle:@"提示"
                                                  message:tip
                                                  handler:^(UIAlertView *alertView, NSInteger buttonIndex)
              {
                  if (buttonIndex != [alertView cancelButtonIndex]) {
                      
                      if (weakSelf.range < HPMessageRangeAll) {
                          weakSelf.range++;
                      }
                      
                      [weakSelf refresh:nil];
                  }
              }];
         }
     }];
}

- (void)test {
    [self scrollToBottomAnimated:YES];
}

#pragma mark - actions
- (void)action:(id)sender {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"刷新", @"最近三天", @"本周", @"全部", nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self refresh:nil];
            break;
        case 1:
            _range = HPMessageRangeLatest;
            [self refresh:nil];
            break;
        case 2:
            _range = HPMessageRangeCurrentWeek;
            [self refresh:nil];
            break;
        case 3:
            _range = HPMessageRangeAll;
            [self refresh:nil];
            break;
        default:
            break;
    }
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _messages.count;
}

#pragma mark - Messages view delegate: REQUIRED

- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
    __weak typeof(self) weakSelf = self;
    [self.view endEditing:YES];
    [SVProgressHUD showWithStatus:@"发送中..." maskType:SVProgressHUDMaskTypeBlack];
    [HPMessage sendMessageWithUsername:_user.username message:text block:^(NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        } else {
            
            [SVProgressHUD showSuccessWithStatus:@"已送达"];
            
            NSDictionary *newMessage = @{
                                         @"message":text,
                                         @"date":date,
                                         @"username":sender
                                         };
            
            [_messages addObject:newMessage];
            [JSMessageSoundEffect playMessageSentSound];
            
            [weakSelf finishSend];
            [weakSelf scrollToBottomAnimated:YES];
        }
    }];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *current_name = [[_messages objectAtIndex:indexPath.row] objectForKey:@"username"];
    if ([current_name isEqualToString:_user.username]) {
        return JSBubbleMessageTypeIncoming;
    } else {
        return JSBubbleMessageTypeOutgoing;
    }
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(type == JSBubbleMessageTypeIncoming) {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                          color:[UIColor js_bubbleLightGrayColor]];
    }
    
    return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                      color:[UIColor js_bubbleBlueColor]];
}

- (JSMessageInputViewStyle)inputViewStyle
{
    return JSMessageInputViewStyleFlat;
}

- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark - Messages view delegate: OPTIONAL

- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if([cell messageType] == JSBubbleMessageTypeOutgoing) {
        cell.bubbleView.textView.textColor = [UIColor whiteColor];
        
        if([cell.bubbleView.textView respondsToSelector:@selector(linkTextAttributes)]) {
            NSMutableDictionary *attrs = [cell.bubbleView.textView.linkTextAttributes mutableCopy];
            [attrs setValue:[UIColor blueColor] forKey:UITextAttributeTextColor];
            
            cell.bubbleView.textView.linkTextAttributes = attrs;
        }
    }
    
    if(cell.timestampLabel) {
        cell.timestampLabel.textColor = [UIColor lightGrayColor];
        cell.timestampLabel.shadowOffset = CGSizeZero;
        
        static NSDateFormatter *formatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        });
        
        NSDate *date = [[self messageForRowAtIndexPath:indexPath] date];
        cell.timestampLabel.text = [formatter stringFromDate:date];
    }
    
    if(cell.subtitleLabel) {
        cell.subtitleLabel.textColor = [UIColor blackColor];
    }
    
#if TARGET_IPHONE_SIMULATOR
    cell.bubbleView.textView.dataDetectorTypes = UIDataDetectorTypeNone;
#else
    cell.bubbleView.textView.dataDetectorTypes = UIDataDetectorTypeAll;
#endif
}

- (BOOL)shouldPreventScrollToBottomWhileUserScrolling
{
    return YES;
}

- (BOOL)allowsPanToDismissKeyboard
{
    return YES;
}

#pragma mark - Messages view data source: REQUIRED

- (JSMessage *)messageForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *message_info = [_messages objectAtIndex:indexPath.row];
    NSString *text = [message_info objectForKey:@"message"];
    NSDate *date = [message_info objectForKey:@"date"];
    NSString *username = [message_info objectForKey:@"username"];
    
    
    if ([[message_info objectForKey:@"isUnread"] boolValue]) {
        text = S(@"%@ (未读)", text);
    }
    
    return [[JSMessage alloc] initWithText:text sender:username date:date];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender
{
    return nil;
}

@end
