//
//  HPThreadFilterMenu.h
//  HiPDA
//
//  Created by Jiangfan on 16/6/9.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPThreadFilterMenu : UIView

@property (nonatomic, copy) void(^submitBlock)();
@property (nonatomic, strong) NSDictionary *currentFilter;
- (void)updateWithFid:(NSInteger)fid;

@end
