//
//  HPActivity.m
//  HiPDA
//
//  Created by Jichao Wu on 15/12/4.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "HPActivity.h"

@interface HPActivity()

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) void((^actionBlock)());

@end

@implementation HPActivity

- (UIActivityType)activityType
{
    return self.type;
}
- (NSString *)activityTitle
{
    return self.title;
}
- (UIImage *)activityImage
{
    return self.image;
}

+ (instancetype)activityWithType:(NSString *)type
                           title:(NSString *)title
                           image:(UIImage *)image
                     actionBlock:(void (^)())actionBlock
{
    HPActivity *activity = [[self alloc] init];
    
    if (activity) {
        activity.type = type;
        activity.title = title;
        activity.image = image ?: [self imageFromColor:[UIColor blackColor] frame:CGRectMake(0, 0, 0.1f, 0.1f)];
        activity.actionBlock = actionBlock;
    }
    
    return activity;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    ;
    return YES;
}

- (void)performActivity
{
    self.actionBlock();
    self.actionBlock = nil;
    
    [self activityDidFinish:YES];
}

#pragma mark -
+ (UIImage *)imageFromColor:(UIColor *)color frame:(CGRect)frame
{
    UIGraphicsBeginImageContext(frame.size);
    
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(contextRef, [color CGColor]);
    CGContextFillRect(contextRef, frame);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
};

@end
