//
//  UIWebView+HPSafeLoadString.m
//  HiPDA
//
//  Created by Jiangfan on 16/6/9.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "UIWebView+HPSafeLoadString.h"

@implementation UIWebView (HPSafeLoadString)

- (void)hp_safeLoadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    // allowLossyConversion : YES OR NO
    // https://crashlytics.com/solo2/ios/apps/wujichao.hipda/issues/5487f43e65f8dfea154bb6ff
    // [__NSCFString dataUsingEncoding:allowLossyConversion:]: didn't convert all characters
    // webview使用loadHTMLString:baseURL:也是用了dataUsingEncoding:allowLossyConversion方法
    // 但是有时会crash(didn't convert all characters)
    // 它的allowLossyConversion是NO
    
    NSData *htmlData = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    [self loadData:htmlData MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];
}

@end
