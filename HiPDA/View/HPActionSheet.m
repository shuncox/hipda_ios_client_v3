//
//  HPActionSheet.m
//  HiPDA
//
//  Created by Jichao Wu on 15/8/23.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "HPActionSheet.h"

@implementation HPActionSheet

- (id)initWithTitle:(NSString *)title delegate:(id<IBActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelTitle destructiveButtonTitle:(NSString *)destructiveTitle otherButtonTitlesArray:(NSArray *)otherTitlesArray {
    
    if (self = [super initWithTitle:title delegate:delegate cancelButtonTitle:cancelTitle destructiveButtonTitle:destructiveTitle otherButtonTitlesArray:otherTitlesArray]) {
        
        [self setButtonBackgroundColor:rgb(25.f, 25.f, 25.f)];
        [self setButtonTextColor:rgb(216.f, 216.f, 216.f)];
        [self setFont:[UIFont fontWithName:@"STHeitiSC-Light" size:20.f]];
    }
    return self;
}

+ (Class)actionSheetClass {
    if (IS_IPAD) {
        return UIActionSheet.class;
    } else {
        return self.class;
    }
}

@end
