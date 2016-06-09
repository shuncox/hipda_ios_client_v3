//
//  UIWebView+HPSafeLoadString.h
//  HiPDA
//
//  Created by Jiangfan on 16/6/9.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWebView (HPSafeLoadString)

- (void)hp_safeLoadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

@end
