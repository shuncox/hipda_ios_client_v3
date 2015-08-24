//
//  HPStupidBar.m
//  HiPDA
//
//  Created by wujichao on 14-6-13.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPStupidBar.h"
#import "HPSetting.h"

@interface HPStupidBar()

@property (nonatomic, strong) UIButton *leftBtn;
@property (nonatomic, strong) UIButton *centerBtn;
@property (nonatomic, strong) UIButton *rightBtn;


@end

@implementation HPStupidBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _leftBtn = [UIButton new];
        [_leftBtn addTarget:self action:@selector(leftBtnTap:) forControlEvents:UIControlEventTouchUpInside];
        
        _centerBtn = [UIButton new];
        [_centerBtn addTarget:self action:@selector(centerBtnTap:) forControlEvents:UIControlEventTouchUpInside];
        
        _rightBtn = [UIButton new];
        [_rightBtn addTarget:self action:@selector(rightBtnTap:) forControlEvents:UIControlEventTouchUpInside];
        
        if (![Setting boolForKey:HPSettingStupidBarHide]) {
            
            self.backgroundColor = [UIColor redColor];
            self.alpha = 0.1;
            
            _centerBtn.backgroundColor = [UIColor yellowColor];
            _rightBtn.backgroundColor = [UIColor blueColor];
        }
        
        [self addSubview:_leftBtn];
        [self addSubview:_centerBtn];
        [self addSubview:_rightBtn];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.leftBtn.frame = CGRectMake(0, 0, self.width/3, self.height);
    self.centerBtn.frame = CGRectMake(self.width/3, 0, self.width/3, self.height);
    self.rightBtn.frame = CGRectMake(self.width/3*2, 0, self.width/3, self.height);
}

- (void)leftBtnTap:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(leftBtnTap)]) {
        [_delegate leftBtnTap];
    }
}

- (void)centerBtnTap:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(centerBtnTap)]) {
        [_delegate centerBtnTap];
    }
}

- (void)rightBtnTap:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(rightBtnTap)]) {
        [_delegate rightBtnTap];
    }
}

@end
