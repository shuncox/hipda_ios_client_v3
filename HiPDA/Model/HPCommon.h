//
//  HPCommon.h
//  HiPDA
//
//  Created by wujichao on 13-11-12.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSUserDefaults+Convenience.h"

//helper
//
#define IOS7_OR_LATER ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
#define IOS8_OR_LATER ([[[UIDevice currentDevice] systemVersion] compare:@"8.0"] != NSOrderedAscending)
#define IOS9_OR_LATER ([[[UIDevice currentDevice] systemVersion] compare:@"9.0"] != NSOrderedAscending)
#define IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#define NSStandardUserDefaults [NSUserDefaults standardUserDefaults]

#define HP_SCREEN_WIDTH (CGRectGetWidth([[UIScreen mainScreen] bounds]))
#define HP_CONVERT_WIDTH(a) (ceilf((a)*kScreenWidth/320.f))
#define HP_CONVERT_HEIGHT(a) (ceilf((a)*kScreenHeight/568.f))


// Copy from Tweet4China
// Created by Jason Hsu

#define kTabBarHeight 44
#define kIPadTabBarWidth 84
#define kIPADMainViewWidth 626


#define GCDBackgroundThread dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define GCDMainThread dispatch_get_main_queue()

#define dp(filename) [([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]) stringByAppendingPathComponent:filename]

#define tp(filename) [([NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0])stringByAppendingPathComponent:filename]

#define ccr(x, y, w, h) CGRectMake(floorf(x), floorf(y), floorf(w), floorf(h))
#define ccp(x, y) CGPointMake(floorf(x), floorf(y))
#define ccs(w, h) CGSizeMake(floorf(w), floorf(h))
#define edi(top, left, bottom, right) UIEdgeInsetsMake(floorf(top), floorf(left), floorf(bottom), floorf(right))
#define cgrgba(r, g, b, a) [[UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a] CGColor]
#define cgrgb(r, g, b) [[UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1] CGColor]
#define rgba(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define rgb(r, g, b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1]

#define bw(w) [UIColor colorWithWhite:w/255.0f alpha:1]
#define bwa(w, a) [UIColor colorWithWhite:w/255.0f alpha:a]
#define L(s) NSLog(@"%@", s);
#define LR(rect) NSLog(@"%@", NSStringFromCGRect(rect));
#define LF(f,...) NSLog(f,##__VA_ARGS__);
#define S(f,...) [NSString stringWithFormat:f,##__VA_ARGS__]

#define kBlackColor [UIColor blackColor]
#define kWhiteColor [UIColor whiteColor]
#define kClearColor [UIColor clearColor]
#define kGrayColor [UIColor grayColor]
#define kLightBlueColor rgb(141, 157, 168)

#define kWinWidth [HSUCommonTools winWidth]
#define kWinHeight [HSUCommonTools winHeight]

#define TWENGINE [HSUTwitterAPI shared]

#define iOS_Ver MIN([[UIDevice currentDevice].systemVersion floatValue], __IPHONE_OS_VERSION_MAX_ALLOWED/10000.0)

#define IPAD [HSUCommonTools isIPad]
#define IPHONE [HSUCommonTools isIPhone]

#define kNamedImageView(s) [[UIImageView alloc] initWithImage:[UIImage imageNamed:s]]

#define GRAY_INDICATOR [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]

#define MyScreenName [TWENGINE myScreenName]

#define DEF_NavitationController_Light [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil]

#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kScreenWidth [UIScreen mainScreen].bounds.size.width


#import "UIImage+Color.h"
#import "UIColor+iOS7Colors.h"

// const
//
#define kHPKeychainService @"HPAccount"
#define kHPAccountUID @"HPAccountUID"
#define kHPAccountUserName @"HPAccountUserName"

/*
#define kHPLittleTail @"HPLittleTail"
#define kHPLittleTailThreadId @"HPLittleTailThreadId"
#define kHPisShowAvatar @"HPisShowAvatar"

#define kHPFontSize @"HPFontSize1"
#define kHPLineHeightMultiple @"HPLineHeightMultiple1"
#define kHPisUseSystemFont @"HPisUseSystemFontItem"

#define kHPForumsID @"HPForumsID"
#define kHPForumsTitle @"HPForumsTitle"
#define kHPisOrderByDateline @"HPisOrderByDateline"
#define kHPisNightMode @"kHPisNightMode"
#define kHPisAutoRefresh @"HPisAutoRefresh"
#define kHPisLazyLoad @"HPisLazyLoad"
*/
 
#define TAG_NightModeView 149410

#define HP_QINIU_SUFFIX @"v.html?c="
#define HP_QINIU_PREFIX ([NSString stringWithFormat:@"http://hpclient.qiniudn.com/%@", HP_QINIU_SUFFIX])
#define HP_MESSAGE_CELL_TAP_IMAGE @"HP_MESSAGE_CELL_TAP_IMAGE"

#define HP_WWW_BASE_URL @"www.hi-pda.com"
#define HP_CNC_BASE_URL @"cnc.hi-pda.com"
#define HP_WWW_BASE_IP @"58.215.45.20"
#define HP_CNC_BASE_IP @"58.215.45.20"

#define HPSettingBaseURL @"HPSettingBaseURL"
#define HPSettingForceDNS @"HPSettingForceDNS"
#define HPBaseURL ([Setting objectForKey:HPSettingBaseURL])

#define HPSettingDic @"HPSettingDic"

#define HPSettingTail @"HPSettingTail"
#define HPSettingFavForums @"HPSettingFavForums"
#define HPSettingFavForumsTitle @"HPSettingFavForumsTitle"

#define HPSettingShowAvatar @"HPSettingShowAvatar"
#define HPSettingOrderByDate @"HPSettingOrderByDate"
#define HPSettingBSForumOrderByDate @"HPSettingBSForumOrderByDate"

#define HPSettingNightMode @"HPSettingNightMode"

#define HPSettingFontSize @"HPSettingFontSize"
#define HPSettingFontSizeAdjust @"HPSettingFontSizeAdjust"
#define HPSettingLineHeight @"HPSettingLineHeight"
#define HPSettingLineHeightAdjust @"HPSettingLineHeightAdjust"
#define HPSettingTextFont @"HPSettingTextFont"
#define HPSettingImageWifi @"HPSettingImageWifi"
#define HPSettingImageWWAN @"HPSettingImageWWAN"
#define kHPNetworkStatus @"HPNetworkStatus"

#define HPSettingBgFetchThread @"HPSettingBgFetchThread"
#define HPSettingBgFetchNotice @"HPSettingBgFetchNotice"

#define HPSettingBGLastMinite @"HPSettingBGLastMinite"

#define HPSettingPreferNotice @"HPSettingPreferNotice"

#define HPSettingIsPullReply @"HPSettingIsPullReply"

#define HPSettingStupidBarDisable @"HPSettingStupidBarDisable"
#define HPSettingStupidBarHide @"HPSettingStupidBarHide"
#define HPSettingStupidBarLeftAction @"HPSettingStupidBarLeftAction"
#define HPSettingStupidBarCenterAction @"HPSettingStupidBarCenterAction"
#define HPSettingStupidBarRightAction @"HPSettingStupidBarRightAction"
#define HPSettingBlockList @"HPSettingBlockList"
#define HPSettingAfterSendShowConfirm @"HPSettingAfterSendShowConfirm"
#define HPSettingAfterSendJump @"HPSettingAfterSendJump"
#define HPSettingDataTrackEnable @"HPSettingDataTrackEnable"
#define HPSettingBugTrackEnable @"HPSettingBugTrackEnable"
#define HPSettingForceLogin @"HPSettingForceLogin"
#define HPSettingSwipeBack @"HPSettingSwipeBack"

#define HPDraft @"HPDraft"

#define HPBgFetchInterval @"HPBgFetchInterval"
#define HPPMCount @"HPPMCount"
#define HPNoticeCount @"HPNoticeCount"
#define HPCheckDisable @"HPCheckDisable"

#define HP_SHOW_MESSAGE_IMAGE_NOTICE @"HP_SHOW_MESSAGE_IMAGE_NOTICE"

//#define kHPImageDisplayViaWWAN @"HPImageDisplayViaWWAN"
//#define kHPImageDisplayViaWifi @"HPImageDisplayViaWifi"
//#define kHPScreenBrightness @"HPScreenBrightness"

// notiy
#define kHPUserLoginSuccess @"HPUserLoginSuccess"
#define kHPUserLoginError @"HPUserLoginError"
#define kHPThemeDidChanged @"HPThemeDidChanged"



#define kHPPOSTFormHash @"HPPOSTFormHash"



// tip
#define kHPBgVCTip @"kHPBgVCTip"
#define kHPHomeTip4Bg @"kHPHomeTip4Bg"
#define kHPPhotoBrowserTip @"kHPPhotoBrowserTip"
#define kHPNightModeTip @"HPNightModeTip"

//
#define kHPNoAccountCode 9567

// image
enum {
    HPImageDisplayStyleFull  = 0,
    HPImageDisplayStyleOne = 1,
    HPImageDisplayStyleNone = 2
} ;
typedef NSInteger HPImageDisplayStyle;



@interface HPCommon : NSObject

+ (NSTimeInterval)timeIntervalSince1970WithString:(NSString *)string;
+ (UINavigationController *)NVCWithRootVC:(UIViewController *)rootVC;
//+ (id)fetchSSIDInfo;
@end
