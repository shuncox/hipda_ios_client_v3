//
//  UIActivity+Blocks.h
//  Created by Ryu Iwasaki on 2013/10/04.
//  Copyright (c) 2013年 Ryu Iwasaki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIActivity (Blocks)

@property (nonatomic, copy) NSString *activityType;
@property (nonatomic, copy) NSString *activityTitle;
@property (nonatomic, strong) UIImage *activityImage;
@property (nonatomic, copy) void((^actionBlock)());

+ (id)activityWithType:(NSString *)type
                 title:(NSString *)title
                 image:(UIImage *)image
           actionBlock:(void (^)())actionBlock;
@end

