//
//  UIDevice+LiveiPhoneX.m
//

#import "UIDevice+iPhoneX.h"
#import "HPCommon.h"

@implementation UIDevice (LiveiPhoneX)

+ (BOOL)hp_isiPhoneX
{
    static BOOL isiPhoneX = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
            // iOS11中返回的safeAreaInsets为（0，0，0，0）；iOS12中返回的safeAreaInsets为（20，0，0，0）
            if ([UIApplication sharedApplication].keyWindow.safeAreaInsets.top > 20) {
                isiPhoneX = YES;
            }
        }
    });
    return isiPhoneX;
}

+ (UIEdgeInsets)hp_safeAreaInsets
{
    static UIEdgeInsets insets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
            insets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
        } else {
            insets = UIEdgeInsetsZero;
        }
    });
    return insets;
}

@end
