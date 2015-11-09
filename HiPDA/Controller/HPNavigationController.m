//
//  HPNavigationController.m
//  HiPDA
//
//  Created by Jichao Wu on 15/5/6.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import "HPNavigationController.h"
#import "HPSetting.h"
#import "UIAlertView+Blocks.h"
#import "SSWDirectionalPanGestureRecognizer.h"

@interface HPNavigationController ()<UIGestureRecognizerDelegate>

@end

@implementation HPNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];


    //
    if (IOS7_OR_LATER) [self showEnableSwipeBackConfirmationIfNeeded];
    if (IOS7_OR_LATER && [Setting boolForKey:HPSettingSwipeBack]) {
        [self fuckPopGestureRecognizer];
    }
}

//https://github.com/zys456465111/CustomPopAnimation/
//http://www.jianshu.com/p/d39f7d22db6c
- (void)fuckPopGestureRecognizer
{
    UIGestureRecognizer *gesture = self.interactivePopGestureRecognizer;
    gesture.enabled = NO;
    UIView *gestureView = gesture.view;
    SSWDirectionalPanGestureRecognizer *popRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] init];
    popRecognizer.delegate = self;
    popRecognizer.direction = SSWPanDirectionRight;
    popRecognizer.maximumNumberOfTouches = 1;
    [gestureView addGestureRecognizer:popRecognizer];

    /**
     * 获取系统手势的target数组
     */
    NSMutableArray *_targets = [gesture valueForKey:@"_targets"];
    /**
     * 获取它的唯一对象，我们知道它是一个叫UIGestureRecognizerTarget的私有类，它有一个属性叫_target
     */
    id gestureRecognizerTarget = [_targets firstObject];
    /**
     * 获取_target:_UINavigationInteractiveTransition，它有一个方法叫handleNavigationTransition:
     */
    id navigationInteractiveTransition = [gestureRecognizerTarget valueForKey:@"_target"];
    /**
     * 通过前面的打印，我们从控制台获取出来它的方法签名。
     */
    SEL handleTransition = NSSelectorFromString(@"handleNavigationTransition:");
    /**
     * 创建一个与系统一模一样的手势，我们只把它的类改为UIPanGestureRecognizer
     */
    [popRecognizer addTarget:navigationInteractiveTransition action:handleTransition];
}

- (void)showEnableSwipeBackConfirmationIfNeeded {
    NSString *popTipKey = @"popTipKey";
    if (![Setting boolForKey:HPSettingSwipeBack]
        && ![NSStandardUserDefaults objectForKey:popTipKey]
        && ![[NSStandardUserDefaults stringForKey:kHPAccountUserName or:@""] isEqualToString:@"wujichao"]) {

        [NSStandardUserDefaults saveObject:@"xxoo" forKey:popTipKey];
        [UIAlertView showConfirmationDialogWithTitle:@"全屏拖动返回"
                                             message:
         @"你好, 我更新了全屏拖动返回的机制\n试用请按Yes.\n"
         @"注意事项: "
         @"1. 重启 App 后生效\n"
         @"2. 开启全局返回需要hack系统的右边缘返回手势, 所以有可能会有工作不正常\n"
         @"经过我近一个月的测试, 只出现过几次不正常的情况\n你可以在设置中随时关闭这个功能\n"
         @"3. 如果你遇到不正常的情况且可以重现, 请联系我, 我们一起把它优化好 ~"
                                             handler:^(UIAlertView *alertView, NSInteger buttonIndex)
        {
            if (buttonIndex == alertView.cancelButtonIndex) {
                ;
            } else {
                [Setting saveBool:YES forKey:HPSettingSwipeBack];
            }
        }];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    /**
     * 这里有两个条件不允许手势执行，1、当前控制器为根控制器；2、如果这个push、pop动画正在执行（私有属性）
     */
    return self.viewControllers.count != 1 && ![[self valueForKey:@"_isTransitioning"] boolValue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
