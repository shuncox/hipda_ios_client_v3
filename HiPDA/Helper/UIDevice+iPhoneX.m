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
            if (!UIEdgeInsetsEqualToEdgeInsets([UIApplication sharedApplication].keyWindow.safeAreaInsets,
                                              UIEdgeInsetsZero)) {
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
