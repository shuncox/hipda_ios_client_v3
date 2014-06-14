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
        
        _leftBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, frame.size.width/3, frame.size.height)];
        [_leftBtn addTarget:self action:@selector(leftBtnTap:) forControlEvents:UIControlEventTouchUpInside];
        
        _centerBtn = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width/3, 0, frame.size.width/3, frame.size.height)];
        [_centerBtn addTarget:self action:@selector(centerBtnTap:) forControlEvents:UIControlEventTouchUpInside];
        
        _rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width/3*2, 0, frame.size.width/3, frame.size.height)];
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
