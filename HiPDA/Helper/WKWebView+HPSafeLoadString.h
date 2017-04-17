//
//  WKWebView+HPSafeLoadString.h
//  HiPDA
//
//  Created by Jiangfan on 2017/4/4.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKWebView (HPSafeLoadString)

- (void)hp_safeLoadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

@end
