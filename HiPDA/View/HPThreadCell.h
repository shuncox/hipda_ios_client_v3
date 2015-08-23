//
//  HPThreadCell.h
//  HiPDA
//
//  Created by wujichao on 14-3-17.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCSwipeTableViewCell.h"

@class HPThread;
@class HPUser;

@protocol HPThreadCellDelegate <NSObject>
- (void)didClickAvatar:(HPUser *)user;
@end

@interface HPThreadCell : MCSwipeTableViewCell

@property (nonatomic, strong) HPThread *thread;
@property (nonatomic, weak)id<HPThreadCellDelegate> hp_delegate;

- (void)configure:(HPThread *)thread;

+ (CGFloat)heightForCellWithThread:(HPThread *)thread width:(CGFloat)width;

- (void)markRead;
- (UIView *)viewWithImageName:(NSString *)imageName;
@end
