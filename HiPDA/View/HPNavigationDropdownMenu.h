//
//  PFNavigationDropdownMenu.h
//  PFNavigationDropdownMenu
//
//  Created by Cee on 02/08/2015.
//  Copyright (c) 2015 Cee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPNavigationDropdownMenu : UIView
- (instancetype)initWithTitle:(NSString *)title
                   customView:(UIView *)customView
                containerView:(UIView *)containerView;
- (void)setMenuTitleText:(NSString *)title;
- (void)dismiss;
@end
