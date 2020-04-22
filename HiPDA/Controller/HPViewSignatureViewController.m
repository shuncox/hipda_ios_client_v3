//
//  HPViewSignatureViewController.m
//  HiPDA
//
//  Created by Jiangfan on 16/6/5.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "HPViewSignatureViewController.h"


#import "HPSFSafariViewController.h"
#import "HPPostViewController.h"
#import "HPThread.h"


@interface HPViewSignatureViewController()

@property (nonatomic, copy) NSString *signature;

@end

@implementation HPViewSignatureViewController

- (instancetype)initWithSignature:(NSString *)signature
{
    self = [super init];
    if (self) {
        _signature = signature;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"个性签名";
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    
    NSString *html = [NSString stringWithFormat:@"<!DOCTYPE html> <html> <head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\" /></head> <body style=\"background-color:#f1f1ef;\">%@</body> </html>", self.signature];
    [webView loadHTMLString:html baseURL:nil];
}

@end
