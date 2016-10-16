//
//  HPAppDelegate.m
//  HiPDA
//
//  Created by wujichao on 13-11-6.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPAppDelegate.h"
#import "SWRevealViewController.h"
#import "HPThreadViewController.h"
#import <AFNetworking.h>
#import "HPAccount.h"
#import "HPHttpClient.h"
#import "HPMessage.h"
#import "HPRearViewController.h"
#import "HPSetting.h"
#import "HPThreadViewController.h"
#import "HPDatabase.h"
#import "NSUserDefaults+Convenience.h"
#import "EGOCache.h"
#import "UIAlertView+Blocks.h"
#import "NSString+Additions.h"
#import "HPMessage.h"
#import "HPNotice.h"
#import "HPURLProtocol.h"
#import "HPHotPatch.h"
#import "NSRegularExpression+HP.h"
#import "HPReadViewController.h"

#define AlertPMTag 1357
#define AlertNoticeTag 2468

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#define UM_APP_KEY (@"543b7fe7fd98c59dcb0418ef")
#define UM_APP_KEY_DEV (UM_APP_KEY)

@interface HPAppDelegate()

@property (nonatomic, strong)HPRearViewController *rearViewController;
@property (nonatomic, strong)UIAlertView *notificationAlertView;

@end
@implementation HPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[HPHotPatch shared] check];
    
    //
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // clean
    if ([NSStandardUserDefaults objectForKey:@"hp-mark-old-273"] == nil) {
        [self clean];
        [NSStandardUserDefaults saveObject:@"whoiam" forKey:@"hp-mark-old-273"];
        NSLog(@"clean done");
    } else {
        NSLog(@"clean already");
    }
    
    //
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:10 * 1024 * 1024 diskCapacity:50 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    //
    NSData *cookiesdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"kUserDefaultsCookie"];
    if([cookiesdata length]) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
        NSHTTPCookie *cookie;
        for (cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
    
    // NetworkActivityIndicator
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    
    // defualt setting
    //
    [Setting loadSetting];
    
    
    //
    [HPURLProtocol registerURLProtocolIfNeed];
    
    
    // reachabilty
    //
    HPHttpClient *client = [HPHttpClient sharedClient];
    [client setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSArray *names = @[@"Unknown ", @"NotReachable", @"WWAN", @"Wifi"];
        NSString *s = [names objectAtIndex:(status+1) % names.count];
        NSLog(@"ReachabilityStatusChange %@", s);
    }];
    
    
    //
    [HPDatabase prepareDb];
    
    // dark
    if ([Setting boolForKey:HPSettingNightMode]) {
        [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
    
    //
    _rearViewController = [HPRearViewController sharedRearVC];
    UINavigationController *frontNavigationController = [HPRearViewController threadNavViewController];
    
	SWRevealViewController *revealController = [[SWRevealViewController alloc] initWithRearViewController:_rearViewController frontViewController:frontNavigationController];
    
    revealController.rearViewRevealWidth = 100.f;
    revealController.rearViewRevealOverdraw = 0.f;
    revealController.frontViewShadowRadius = 0.f;

    revealController.delegate = _rearViewController;
    
    self.viewController = revealController;
    self.window.rootViewController = self.viewController;
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    [[HPAccount sharedHPAccount] startCheckWithDelay:30.f];
    
    UILocalNotification *localNotification =
    [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        [self FinishLaunchingWithReciveLocalNotification:localNotification];
    }

    [self setupBgFetch];
    
    BOOL dataTrackingEnable = [Setting boolForKey:HPSettingDataTrackEnable];
    BOOL bugTrackingEnable = [Setting boolForKey:HPSettingBugTrackEnable];
    if (bugTrackingEnable) {
        [Fabric with:@[[Crashlytics class]]];
    }

    if (dataTrackingEnable) {
        
        //[Flurry setCrashReportingEnabled:NO];
        //[Flurry startSession:@"PM72Q4WCN9DCMMSFDJC6"];
        //[Flurry setDebugLogEnabled:YES];
        //note
        [MobClick setCrashReportEnabled:NO];
        [MobClick setLogEnabled:NO];
        [MobClick setBackgroundTaskEnabled:NO];
        [MobClick setLatency:30];
        
#if DEBUG
        [MobClick startWithAppkey:UM_APP_KEY_DEV reportPolicy:BATCH channelId:@"debug"];
        //[MobClick setLogEnabled:YES];
#else
        [MobClick startWithAppkey:UM_APP_KEY reportPolicy:BATCH channelId:nil];
#endif
        
    }
    
    // 友盟在线参数, 配置后十分钟生效
#if DEBUG
    [UMOnlineConfig updateOnlineConfigWithAppkey:UM_APP_KEY_DEV];
    [UMOnlineConfig setLogEnabled:YES];
#else
    [UMOnlineConfig updateOnlineConfigWithAppkey:UM_APP_KEY];
#endif
    
    [Flurry trackUserIfNeeded];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    //
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:HPBaseURL]];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
    //NSLog(@"save cookies %@", data);
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"kUserDefaultsCookie"];
    
    if ([Setting boolForKey:HPSettingBugTrackEnable]) {
        CLSNSLog(@"-> applicationWillResignActive");
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // reset applicationIconBadgeNumber
    application.applicationIconBadgeNumber  = [[HPAccount sharedHPAccount] badgeNumber];
    
    if ([Setting boolForKey:HPSettingBugTrackEnable]) {
        CLSNSLog(@"-> applicationDidEnterBackground");
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    // 省流量
    //[[BFHotPatch shared] check];
    
    if ([Setting boolForKey:HPSettingBugTrackEnable]) {
        CLSNSLog(@"-> applicationWillEnterForeground");
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
//    [self routeTo:@{@"tid": @"1831924"}];
    [self checkPasteboard];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if ([Setting boolForKey:HPSettingBugTrackEnable]) {
        CLSNSLog(@"-> applicationDidBecomeActive");
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [self showAlert];
}

//http://stackoverflow.com/questions/17276898/mpmovieplayerviewcontroller-allow-landscape-mode
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    UIViewController *vc = [self hp_topViewController];
    if (IOS9_2_OR_LATER && [vc isKindOfClass:NSClassFromString(@"SFSafariViewController")])
    {
        if (vc.isBeingDismissed)
        {
            return UIInterfaceOrientationMaskPortrait;
        }
        else
        {
            return UIInterfaceOrientationMaskAllButUpsideDown;
        }
    }
    else
    {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)showAlert {
    
    //clear
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    NSInteger pm_count = [Setting integerForKey:HPPMCount];
    NSInteger notice_count = [Setting integerForKey:HPNoticeCount];
    
    NSString *msg = nil;
    int tag = -1;
    if (pm_count > 0) {
        msg = S(@"您有新的短消息(%d)", pm_count);
        tag = AlertPMTag;
    } else if (notice_count > 0){
        msg = S(@"您有新的帖子消息(%d)", notice_count);
        tag = AlertNoticeTag;
    } else {
        
        //
        return;
    }
    
    NSLog(@"__ %@", _notificationAlertView);
    if (!_notificationAlertView) {
        _notificationAlertView = [[UIAlertView alloc] initWithTitle:@"提醒"
                                                            message:msg
                                                           delegate:self
                                                  cancelButtonTitle:@"忽略"
                                                  otherButtonTitles:@"查看", nil];
        _notificationAlertView.tag = tag;
        [_notificationAlertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex == 0) {
        
        if (alertView.tag == AlertPMTag) {
            
            [HPMessage ignoreMessage];
            
        } else if (alertView.tag == AlertNoticeTag) {
            
            [HPNotice ignoreNotice];
            
        } else {
            ;
        }

    } else if (buttonIndex == 1) {
        if (_rearViewController) {
            
            if (alertView.tag == AlertPMTag) {
                
                [_rearViewController switchToMessageVC];
                
            } else if (alertView.tag == AlertNoticeTag) {
                
                [_rearViewController switchToNoticeVC];
                
            } else {
                ;
            }
        } else {
            ;
        }
        
    } else {
        ;
    }
    
    _notificationAlertView = nil;
}

- (void)FinishLaunchingWithReciveLocalNotification:(UILocalNotification *)localNotification {
    
    NSLog(@"Notification Body: %@",localNotification.alertBody);
    NSLog(@"%@", localNotification.userInfo);
    
    [self showAlert];
}

- (void)setupBgFetch {
    BOOL enableBgFetch = [Setting boolForKey:HPSettingBgFetchNotice];
    if (enableBgFetch) {
        
        NSInteger interval = [Setting integerForKey:HPBgFetchInterval];
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:interval * 60.f];
        
        NSString *username = [NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""];
        BOOL haveAsk = [NSStandardUserDefaults boolForKey:kHPAskNotificationPermission or:NO];
        BOOL haveLogin = [HPAccount isSetAccount] && ![username isEqualToString:@"wujichao"];
        
        if (!haveAsk && haveLogin && IOS8_OR_LATER) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"请求后台伪推送权限" message:@"Hi, 俺利用了iOS7+的后台应用程序刷新来实现新消息的推送，不是很及时，但有总比没有好。\n但是，发送本地推送需要您的授权，若您需要这个功能请点击授权" delegate:nil cancelButtonTitle:@"不" otherButtonTitles:@"授权", nil];
            [alert showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex != alertView.cancelButtonIndex) {
                    [[HPAccount sharedHPAccount] askLocalNotificationPermission];
                } else {
                    [Setting saveBool:NO forKey:HPSettingBgFetchNotice];
                }
            }];
        }
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if (![Setting boolForKey:HPSettingBgFetchNotice]) {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    [[HPAccount sharedHPAccount] setNoticeRetrieveBlock:^(UIBackgroundFetchResult result) {
        // log
        //
        NSMutableArray *log = [NSMutableArray arrayWithArray:[NSStandardUserDefaults objectForKey:@"HPBgFetchLog"]];
        
        if (log.count > 233) {
            [log removeLastObject];
        }
        
        NSInteger interval = [Setting integerForKey:HPBgFetchInterval];
        [log insertObject:@{@"interval":@(interval),
                            @"date":[NSDate date],
                            @"result":@(result)} //0 NewData, 1 NoData, 2 Failed
                  atIndex:0];
        [NSStandardUserDefaults saveObject:log forKey:@"HPBgFetchLog"];
        //NSLog(@"%@", log);
        //
        //
        completionHandler(result);
    }];
    [[HPAccount sharedHPAccount] startCheckWithDelay:0.f];
}

- (void)clean {
    // NSUserDefaults
    //
    
    // clear cookies
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }

    // clear egocache
    [[EGOCache globalCache] clearCache];
}

#pragma mark - 
- (void)checkPasteboard
{
    UIPasteboard *appPasteBoard = [UIPasteboard generalPasteboard];
    NSString *content = appPasteBoard.string;
    if (!content.length) {
        return;
    }
    
    // 去重
    static NSMutableSet *history = nil;
    if (!history) {
        history = [[NSMutableSet alloc] init];
    }
    if ([history containsObject:content]) {
        NSLog(@"history hit %@", content);
        return;
    } else {
        [history addObject:content];
    }
    
    // match
    NSString *tid = [RX(@"hi-pda\\.com/forum/viewthread\\.php\\?tid=(\\d+)") firstMatchValue:content];
    if (tid) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"是否进入id为%@的帖子", tid] delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"进入", nil];
        [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [Flurry logEvent:@"Pasteboard Tid"];
                [self routeTo:@{@"tid": tid}];
            }
        }];
        return;
    }
    // anything else
}

#pragma mark -
- (void)routeTo:(NSDictionary *)path
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"routeTo %@", path);
        
        SWRevealViewController *revealController = self.viewController;
        UINavigationController *frontNavigationController = (id)revealController.frontViewController;
        
        // dismiss presentedViewController
        UIViewController *presentedViewController = revealController.rearViewController.presentedViewController;
        presentedViewController = presentedViewController ?: frontNavigationController.presentedViewController;
        presentedViewController = presentedViewController ?: revealController.presentedViewController;
        if (presentedViewController) {
            [presentedViewController dismissViewControllerAnimated:NO
                                                        completion:nil];
        }
        
        // close drawer
        if (revealController.frontViewPosition != FrontViewPositionLeft) {
            [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
        }
        
        if ([path objectForKey:@"fid"]) { //板块
            ;
        } else if ([path objectForKey:@"tid"]) { //帖子
            
            HPThread *t = [HPThread new];
            t.tid = [path[@"tid"] integerValue];
            HPReadViewController *readVC = [[HPReadViewController alloc] initWithThread:t];
            [frontNavigationController pushViewController:readVC animated:YES];
            
        } else if ([path objectForKey:@"pid"]) { //回复
            ;
        } else if ([path objectForKey:@"userCenter"]) {
            ;
        } else {
            ;
        }
    });
}

#pragma mark - topViewController
//http://stackoverflow.com/questions/6131205/iphone-how-to-find-topmost-view-controller/20515681#20515681
- (UIViewController*)hp_topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    
    if ([rootViewController isKindOfClass:[SWRevealViewController class]]) {
        SWRevealViewController *v = (SWRevealViewController *)rootViewController;
        return [self topViewControllerWithRootViewController:v.frontViewController];
    } else if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

@end
