//
//  WKWebView+Synchronize.h
//  HiPDA
//
//  Created by Jiangfan on 2017/4/17.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKWebView (Synchronize)

- (id)stringByEvaluatingJavaScriptFromString:(NSString *)script;

@end
