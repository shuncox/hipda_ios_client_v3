//
//  UIViewController+Tracking.m
//  HiPDA
//
//  Created by Jichao Wu on 15/10/27.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "UIViewController+Tracking.h"
#import <objc/runtime.h>
#import <Crashlytics/Crashlytics.h>

//http://nshipster.com/method-swizzling/
@implementation UIViewController (Tracking)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(xxx_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        // ...
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

#pragma mark - Method Swizzling

- (void)xxx_viewWillAppear:(BOOL)animated {
    [self xxx_viewWillAppear:animated];
    // 给 Crashlytics 的报告提供上下文
    // CLS_LOG 会带有当前的function和line, 都是viewWillAppear, 木有必要, 直接用CLSNSLog
    CLSNSLog(@"-> %@", NSStringFromClass(self.class));
}

@end