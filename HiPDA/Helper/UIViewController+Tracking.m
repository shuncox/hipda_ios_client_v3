//
//  UIViewController+Tracking.m
//  HiPDA
//
//  Created by Jichao Wu on 15/10/27.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "UIViewController+Tracking.h"
#import <objc/runtime.h>
#import "HPCrashReport.h"

//http://nshipster.com/method-swizzling/
@implementation UIViewController (Tracking)

static inline void SwizzleSelector(Class class, SEL originalSelector, SEL swizzledSelector)
{
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
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SwizzleSelector(class, @selector(viewDidLoad), @selector(xxx_viewDidLoad));
        SwizzleSelector(class, @selector(viewWillAppear:), @selector(xxx_viewWillAppear:));
        SwizzleSelector(class, @selector(viewDidAppear:), @selector(xxx_viewDidAppear:));
        SwizzleSelector(class, @selector(viewWillDisappear:), @selector(xxx_viewWillDisappear:));
        SwizzleSelector(class, @selector(viewDidDisappear:), @selector(xxx_viewDidDisappear:));
    });
}

#pragma mark - Method Swizzling

- (void)xxx_viewDidLoad
{
    [self xxx_viewDidLoad];
    DDLogInfo(@"[PAGE][DidLoad][%@]", NSStringFromClass(self.class));
}

- (void)xxx_viewWillAppear:(BOOL)animated {
    [self xxx_viewWillAppear:animated];
    HPCrashLog(@"-> %@", NSStringFromClass(self.class));
    DDLogInfo(@"[PAGE][WillAppear][%@]", NSStringFromClass(self.class));
}

- (void)xxx_viewDidAppear:(BOOL)animated
{
    [self xxx_viewDidAppear:animated];
    DDLogInfo(@"[PAGE][DidAppear][%@]", NSStringFromClass(self.class));
}

- (void)xxx_viewWillDisappear:(BOOL)animated
{
    [self xxx_viewWillDisappear:animated];
    DDLogInfo(@"[PAGE][WillDisappear][%@]", NSStringFromClass(self.class));
}

- (void)xxx_viewDidDisappear:(BOOL)animated
{
    [self xxx_viewDidDisappear:animated];
    DDLogInfo(@"[PAGE][DidDisappear][%@]", NSStringFromClass(self.class));
}

@end
