//
//  PFNavigationDropdownMenu.m
//  PFNavigationDropdownMenu
//
//  Created by Cee on 02/08/2015.
//  Copyright (c) 2015 Cee. All rights reserved.
//

#import "HPNavigationDropdownMenu.h"

@interface Configuration : NSObject
@property (nonatomic, strong) UIImage *arrowImage;
@property (nonatomic, assign) CGFloat arrowPadding;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, strong) UIColor *maskBackgroundColor;
@property (nonatomic, assign) CGFloat maskBackgroundOpacity;
@end
@implementation Configuration
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setDefaultValue];
    }
    return self;
}
- (void)setDefaultValue
{
    self.animationDuration = 0.3;
    self.arrowImage = [[UIImage imageNamed:@"HPNavigationDropdownMenu.bundle/arrow_down_icon"] changeColor:[UIColor blackColor]];
    self.arrowPadding = 12;
    self.maskBackgroundColor = [UIColor blackColor];
    self.maskBackgroundOpacity = 0.3;
}
@end

@interface HPNavigationDropdownMenu()
@property (nonatomic, strong) Configuration *configuration;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, assign) CGRect mainScreenBounds;
@property (nonatomic, strong) UIButton *menuButton;
@property (nonatomic, strong) UILabel *menuTitle;
@property (nonatomic, strong) UIImageView *menuArrow;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign) BOOL isShown;
@property (nonatomic, assign) BOOL busy;
@property (nonatomic, assign) CGFloat navigationBarHeight;
@end

@implementation HPNavigationDropdownMenu
- (instancetype)initWithTitle:(NSString *)title
                   customView:(UIView *)customView
                containerView:(UIView *)containerView;
{
    CGRect frame = CGRectMake(0, 0, 1000, 44);
    self = [super initWithFrame:frame];
    if (self) {
        // Init properties
        self.configuration = [[Configuration alloc] init];
        self.containerView = containerView;
        self.customView = customView;
        self.navigationBarHeight = 44;
        self.mainScreenBounds = [UIScreen mainScreen].bounds;
        self.isShown = NO;
        
        // Init button as navigation title
        self.menuButton = [[UIButton alloc] initWithFrame:frame];
        [self.menuButton addTarget:self action:@selector(menuButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.menuButton];
        
        self.menuTitle = [[UILabel alloc] initWithFrame:frame];
        self.menuTitle.text = title;
        self.menuTitle.textColor = [UINavigationBar appearance].titleTextAttributes[NSForegroundColorAttributeName];
        self.menuTitle.textAlignment = NSTextAlignmentCenter;
        self.menuTitle.font = [UIFont boldSystemFontOfSize:17.f];
        [self.menuButton addSubview:self.menuTitle];
        
        self.menuArrow = [[UIImageView alloc] initWithImage:self.configuration.arrowImage];
        [self.menuButton addSubview:self.menuArrow];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.menuButton.frame = self.bounds;

    [self.menuTitle sizeToFit];
    [self.menuArrow sizeToFit];
    
    CGFloat offset = self.superview.frame.size.width/2 - self.frame.size.width/2 - self.frame.origin.x;
    self.menuTitle.center = CGPointMake(self.frame.size.width / 2.f + offset, self.frame.size.height / 2.f);
    self.menuArrow.center = CGPointMake(CGRectGetMaxX(self.menuTitle.frame) + self.configuration.arrowPadding, self.frame.size.height / 2.f + 2);
}

- (void)showMenu
{
    self.busy = YES;
    
    // Init background view (under table view)
    self.backgroundView = [[UIButton alloc] initWithFrame:self.mainScreenBounds];
    [(UIButton *)self.backgroundView addTarget:self action:@selector(menuButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.backgroundView.backgroundColor = self.configuration.maskBackgroundColor;
    
    // Add background view & table view to container view
    [self.containerView addSubview:self.backgroundView];
    [self.containerView addSubview:self.customView];
    
    // Rotate arrow
    [self rotateArrow];
    
    // Change background alpha
    self.backgroundView.alpha = 0;
    
    CGFloat offset = 0;
    if ([self.containerView isKindOfClass:UIScrollView.class]) {
        UIScrollView *v = (UIScrollView *)self.containerView;
        offset = v.contentOffset.y + v.contentInset.top;
    }
    
    CGRect backgroundViewFrame = self.backgroundView.frame;
    backgroundViewFrame.origin.y = offset;
    self.backgroundView.frame = backgroundViewFrame;
    
    // Animation
    CGRect customViewFrame = self.customView.frame;
    customViewFrame.origin.y = offset;
    customViewFrame.origin.y -= customViewFrame.size.height;
    self.customView.frame = customViewFrame;
    
    [UIView animateWithDuration:self.configuration.animationDuration
                     animations:^{
                         CGRect customViewFrame = self.customView.frame;
                         customViewFrame.origin.y += customViewFrame.size.height;
                         self.customView.frame = customViewFrame;
                         
                         self.backgroundView.alpha = self.configuration.maskBackgroundOpacity;
                     } completion:^(BOOL finished) {
                         self.busy = NO;
                     }];
}

- (void)hideMenu
{
    self.busy = YES;
    
    // Rotate arrow
    [self rotateArrow];
    
    // Change background alpha
    self.backgroundView.alpha = self.configuration.maskBackgroundOpacity;
    
    
    [UIView animateWithDuration:self.configuration.animationDuration
                     animations:^{
                         CGRect customViewFrame = self.customView.frame;
                         customViewFrame.origin.y -= customViewFrame.size.height;
                         self.customView.frame = customViewFrame;
                         
                         self.backgroundView.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self.customView removeFromSuperview];
                         [self.backgroundView removeFromSuperview];
                         self.busy = NO;
                     }];
    
}

- (void)rotateArrow
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:self.configuration.animationDuration
                     animations:^{
                         __strong typeof(weakSelf) strongSelf = weakSelf;
                         strongSelf.menuArrow.transform = CGAffineTransformRotate(strongSelf.menuArrow.transform, 180 * (CGFloat)(M_PI / 180));
                     }];
}

- (void)setMenuTitleText:(NSString *)title
{
    self.menuTitle.text = title;
    [self setNeedsLayout];
}

- (void)setMenuTitleColor:(UIColor *)color
{
    self.menuTitle.textColor = color;
}

- (void)menuButtonTapped:(UIButton *)sender
{
    self.isShown = !self.isShown;
}

- (void)dismiss
{
    self.isShown = NO;
}

- (void)dismissIfNeeded
{
    if (self.isShown) {
        self.isShown = NO;
    }
}

- (void)setIsShown:(BOOL)isShown
{
    if (self.busy) {
        return;
    }
    if ([self.containerView isKindOfClass:UIScrollView.class]) {
        UIScrollView *v = (UIScrollView *)self.containerView;
        if (v.decelerating) {
            return;
        }
    }
    
    _isShown = isShown;
    
    if (isShown) {
        [self showMenu];
    } else {
        [self hideMenu];
    }
    
    if ([self.containerView isKindOfClass:UIScrollView.class]) {
        ((UIScrollView *)self.containerView).scrollEnabled = !isShown;
    }
}

@end
