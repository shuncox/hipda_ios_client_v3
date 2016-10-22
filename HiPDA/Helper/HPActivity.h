//
//  HPActivity.h
//  HiPDA
//
//  Created by Jichao Wu on 15/12/4.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPActivity : UIActivity

+ (instancetype)activityWithType:(NSString *)type
                           title:(NSString *)title
                           image:(UIImage *)image
                     actionBlock:(void (^)())actionBlock;

@end
