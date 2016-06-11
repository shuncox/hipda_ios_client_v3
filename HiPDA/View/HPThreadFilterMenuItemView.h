//
//  HPThreadFilterMenuItemView.h
//  HiPDA
//
//  Created by Jiangfan on 16/6/10.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPThreadFilterMenuItemView : UIView

@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *selectedValue;
@property (nonatomic, readonly, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, copy) void(^didSelect)(HPThreadFilterMenuItemView *view, NSString *value);

- (void)deselect;

@end
