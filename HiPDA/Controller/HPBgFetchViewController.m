//
//  HPBgFetchViewController.m
//  HiPDA
//
//  Created by wujichao on 14-4-12.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPBgFetchViewController.h"
#import "HPSetting.h"
#import "MultilineTextItem.h"
#import "HPAppDelegate.h"
#import "HPBackgroundFetchService.h"


@interface HPBgFetchViewController ()

@property (strong, nonatomic) RETableViewManager *manager;
@property (strong, nonatomic) RETableViewSection *forumSection;

@end

@implementation HPBgFetchViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // update bgFetch setting
    [[HPBackgroundFetchService instance] setupBgFetch];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"后台应用程序刷新";
    
    
    _manager = [[RETableViewManager alloc] initWithTableView:self.tableView delegate:self];
    
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:nil];
    [_manager addSection:section];
    
    
    BOOL enableBgFetchNotice = [Setting boolForKey:HPSettingBgFetchNotice];
    REBoolItem *enableBgFetchNoticeItem = [REBoolItem itemWithTitle:@"新消息提醒" value:enableBgFetchNotice switchValueChangeHandler:^(REBoolItem *item) {
        
        NSLog(@"enableBgFetchNotice Value: %@", item.value ? @"YES" : @"NO");
        [Setting saveBool:item.value forKey:HPSettingBgFetchNotice];
        
        [Flurry logEvent:@"Setting ToggleBgFetchNotice" withParameters:@{@"flag":@(item.value)}];
    }];
    
    NSInteger interval = [Setting integerForKey:HPBgFetchInterval];
    NSInteger min_interval = 10;
    NSInteger max_interval = 100;
    // v3.4.1 设置了 interval 最大为360, 但真机测试, 当interval > 100时, 基本得不到刷新
    // HPAppDelegate.m:292 中 尝试修正了当max_interval>100时
    
    CGFloat value = ((float)interval-min_interval)/(max_interval-min_interval);
    // 10min ~ 1.5h(100)
    // (x - 10) / (100 - 10)
    REFloatItem *intervalItem = [REFloatItem itemWithTitle:[NSString stringWithFormat:@"刷新间隔: 约每%ld分", interval]
                                                     value:value
                                  sliderValueChangeHandler:^(REFloatItem *item) {
                                      CGFloat v = item.value * (max_interval-min_interval) + min_interval;
                                      NSLog(@"Value: %f -> %d", item.value, (int)v);
                                      item.title = [NSString stringWithFormat:@"刷新间隔: 约每%d分", (int)v];
                                      [Setting saveInteger:(int)v forKey:HPBgFetchInterval];
                                      [item reloadRowWithAnimation:UITableViewRowAnimationNone];
                                  }];
    
    self.manager[@"MultilineTextItem"] = @"MultilineTextCell";
    [section addItem:enableBgFetchNoticeItem];
    [section addItem:intervalItem];
    [section addItem:[MultilineTextItem itemWithTitle:
        @"你的 iOS 设备可以根据你使用 HiPDA 的频率和时间智能安排来更新未读提醒并提示您。\n\n"
        @"注意: \n"
        @"1. 谨慎开启, 会额外消耗电量和流量, 刷新的次数和您每天打开 HiPDA 次数大抵相当, iOS 系统会智能安排刷新的频率, 尽可能的减少电量的消耗。\n"
        @"2. 你需要在系统 设置 > 通用 > 应用程序后台刷新中允许 HiPDA 才可以使本页的设置生效。\n"
        @"3. iOS8 系统发送本地推送需要您的授权, 所以您还需要确保在设置中开启 HiPDA 推送的权限。"
    ]];
    
    
    RETableViewSection *logSection = [RETableViewSection sectionWithHeaderTitle:@"Log"];
    
    /*
    @{@"counter":@(counter),
    @"date":[NSDate date],
    @"result":@(result)} //0 NewData, 1 NoData, 2 Failed
    */
    
    NSMutableArray *log = [NSStandardUserDefaults objectForKey:@"HPBgFetchLog"];
    for (NSInteger i = 0; i < log.count; i++) {
        id obj = log[i];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM-dd HH:mm:ss"];
        
        NSString *r = nil;
        switch ([obj[@"result"] integerValue]) {
            case 0:
                r = @"有新消息";
                break;
            case 1:
                r = @"无新消息";
                break;
            case 2:
                r = @"获取失败";
                break;
            default:
                r = @"WTF";
                break;
        }
        
        NSInteger min = 0;
        if (i + 1 < log.count) {
            id obj_last = log[i+1];
            NSDate *last = obj_last[@"date"];
            NSTimeInterval i = [obj[@"date"] timeIntervalSinceDate:last];
            min = i / 60;
        }
        
        NSString *text = [NSString stringWithFormat:@"%@,距上次%02ld分,%@",
                          [formatter stringFromDate:obj[@"date"]],
                          (long)min,
                          r];
        RETableViewItem *item = [[RETableViewItem alloc] initWithTitle:text];
        
        [logSection addItem:item];
    }
    
    [_manager addSection:logSection];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
