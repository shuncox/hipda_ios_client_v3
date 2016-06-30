//
//  PFNavigationDropdownMenu.h
//  PFNavigationDropdownMenu
//
//  Created by Cee on 02/08/2015.
//  Copyright (c) 2015 Cee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPNavigationDropdownMenu : UIView

@property (nonatomic, readonly, assign) BOOL isShown;

- (instancetype)initWithTitle:(NSString *)title
                   customView:(UIView *)customView
                containerView:(UIView *)containerView;
- (void)setMenuTitleText:(NSString *)title;
- (void)setMenuTitleColor:(UIColor *)color;
- (void)dismiss;
- (void)dismissIfNeeded;

@end
