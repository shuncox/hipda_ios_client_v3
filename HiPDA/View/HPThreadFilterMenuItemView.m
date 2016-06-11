//
//  HPThreadFilterMenuItemView.m
//  HiPDA
//
//  Created by Jiangfan on 16/6/10.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "HPThreadFilterMenuItemView.h"

@interface HPThreadFilterMenuItemView()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIView *placeholderView;
@property (nonatomic, strong) UIScrollView *segmentedControlContainer;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@end

@implementation HPThreadFilterMenuItemView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _textLabel = [UILabel new];
        _placeholderView = [UIView new];
        _segmentedControlContainer = [UIScrollView new];
        _segmentedControl = [UISegmentedControl new];
        [_segmentedControl addTarget:self
                              action:@selector(segmentedControlValueChanged:)
                    forControlEvents:UIControlEventValueChanged];
        
        [self addSubview:_textLabel];
        [self addSubview:_placeholderView];
        
        [self addSubview:_segmentedControlContainer];
        [_segmentedControlContainer addSubview:_segmentedControl];
        _segmentedControlContainer.showsHorizontalScrollIndicator = NO;
        
        [_textLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                    forAxis:UILayoutConstraintAxisHorizontal];
        [_textLabel setContentHuggingPriority:UILayoutPriorityRequired
                                      forAxis:UILayoutConstraintAxisHorizontal];

        [_textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.centerY.equalTo(self);
        }];
        // 用来占位, 方便布局
        [_placeholderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_textLabel.mas_right).offset(10);
            make.top.bottom.right.equalTo(self);
        }];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.segmentedControl sizeToFit];
    CGFloat width = self.segmentedControl.frame.size.width;
    CGFloat height = self.segmentedControl.frame.size.height;
    
    CGRect frame = self.placeholderView.frame;
    frame.size.height = height;
    
    if (width <= self.placeholderView.frame.size.width) {
        self.segmentedControlContainer.frame = frame;
        self.segmentedControlContainer.scrollEnabled = NO;
        self.segmentedControl.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    } else {
        self.segmentedControlContainer.frame = frame;
        self.segmentedControlContainer.scrollEnabled = YES;
        self.segmentedControlContainer.contentSize = CGSizeMake(width, height);
        [self scrollSeletedValueToVisible];
    }
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 29.f); // 29.f = segmentedControl的默认高度
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.textLabel.text = title;
}

- (void)setItems:(NSArray *)items
{
    _items = items;
    
    self.segmentedControlContainer.contentOffset = CGPointMake(0, 0);
    [self.segmentedControl removeAllSegments];
    for (NSString *segment in items) {
        [self.segmentedControl insertSegmentWithTitle:segment atIndex:self.segmentedControl.numberOfSegments animated:NO];
    }
    [self setNeedsLayout];
}


- (void)tryToSetSelectedValue:(NSString *)selectedValue
{
    NSInteger index = [self.values indexOfObject:selectedValue];
    if (index == NSNotFound) {
        index = UISegmentedControlNoSegment;
    }
    self.segmentedControl.selectedSegmentIndex = index;
}

- (void)setSelectedValue:(NSString *)selectedValue
{
    NSInteger index = [self.values indexOfObject:selectedValue];
    NSParameterAssert(index != NSNotFound);
    if (index == NSNotFound) index = 0;
    self.segmentedControl.selectedSegmentIndex = index;
}

- (NSString *)selectedValue
{
    NSInteger index = self.segmentedControl.selectedSegmentIndex;
    if (index == UISegmentedControlNoSegment) {
        return nil;
    }
    
    NSParameterAssert(index < self.values.count);
    return [self.values objectAtIndex:index];
}

- (void)deselect
{
    self.segmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment;
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentControl
{
    if (self.didSelect) {
        self.didSelect(self, [self selectedValue]);
    }
}

- (void)scrollSeletedValueToVisible
{
    if (!self.segmentedControlContainer.scrollEnabled ||
        CGRectGetWidth(self.segmentedControl.frame) == 0.f ||
        self.segmentedControl.selectedSegmentIndex == UISegmentedControlNoSegment) {
        return;
    }
    
    // 等待segment布局完成
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *views = self.segmentedControl.subviews;
        views = [views sortedArrayUsingComparator:^NSComparisonResult(UIView *v1, UIView *v2) {
            return v1.frame.origin.x - v2.frame.origin.x;
        }];
        
        NSParameterAssert(self.segmentedControl.selectedSegmentIndex < views.count);
        UIView *view = views[self.segmentedControl.selectedSegmentIndex];
        CGFloat x = view.frame.origin.x + view.frame.size.width;
        if (x > self.segmentedControlContainer.frame.size.width) {
            self.segmentedControlContainer.contentOffset = CGPointMake(x - self.segmentedControlContainer.frame.size.width, 0);
        };
    });
}

@end
