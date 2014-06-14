//
//  HPStupidBar.h
//  HiPDA
//
//  Created by wujichao on 14-6-13.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HPStupidBarDelegate <NSObject>

@optional

- (void)leftBtnTap;
- (void)centerBtnTap;
- (void)rightBtnTap;

@end

@interface HPStupidBar : UIView

@property (nonatomic, weak) id<HPStupidBarDelegate> delegate;

@end
