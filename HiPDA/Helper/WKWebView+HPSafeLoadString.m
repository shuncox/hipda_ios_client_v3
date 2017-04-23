//
//  WKWebView+HPSafeLoadString.m
//  HiPDA
//
//  Created by Jiangfan on 2017/4/4.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "WKWebView+HPSafeLoadString.h"

@implementation WKWebView (HPSafeLoadString)

- (void)hp_safeLoadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    // allowLossyConversion : YES OR NO
    // https://crashlytics.com/solo2/ios/apps/wujichao.hipda/issues/5487f43e65f8dfea154bb6ff
    // [__NSCFString dataUsingEncoding:allowLossyConversion:]: didn't convert all characters
    // webview使用loadHTMLString:baseURL:也是用了dataUsingEncoding:allowLossyConversion方法
    // 但是有时会crash(didn't convert all characters)
    // 它的allowLossyConversion是NO
    
    if (IOS9_OR_LATER) {
        NSData *htmlData = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        [self loadData:htmlData MIMEType:@"text/html" characterEncodingName:@"UTF-8" baseURL:baseURL];
    } else {
        [self loadHTMLString:string baseURL:baseURL];
    }
}

@end
