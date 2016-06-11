//
//  HPViewSignatureViewController.m
//  HiPDA
//
//  Created by Jiangfan on 16/6/5.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "HPViewSignatureViewController.h"


#import "HPSFSafariViewController.h"
#import "HPReadViewController.h"
#import "HPThread.h"
#import "DZWebBrowser.h"


@interface HPViewSignatureViewController()<UIWebViewDelegate>

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
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webView.delegate = self;
    [self.view addSubview:webView];
    
    NSString *html = [NSString stringWithFormat:@"<!DOCTYPE html> <html> <head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\" /></head> <body style=\"background-color:#f1f1ef;\">%@</body> </html>", self.signature];
    [webView loadHTMLString:html baseURL:nil];
}

// 从HPReadViewController复制过来的
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *urlString = [[request URL] absoluteString];
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        RxMatch* match = [urlString firstMatchWithDetails:RX(@"hi-pda\\.com/forum/viewthread\\.php\\?tid=(\\d+)")];
        
        if (match) {
            
            RxMatchGroup *m1 = [match.groups objectAtIndex:1];
            
            HPThread *t = [HPThread new];
            t.tid = [m1.value integerValue];
            HPReadViewController *readVC = [[HPReadViewController alloc] initWithThread:t];
            NSLog(@"[self.navigationController pushViewController:readVC animated:YES];");
            [self.navigationController pushViewController:readVC animated:YES];
            
        } else {
            NSLog(@"here w");
            [self openUrl:request.URL];
        }
        
        return NO;
    }
    
    return YES;
}


- (void)openUrl:(NSURL *)url {
    
    // todo
    // setting safari
    if (IOS9_2_OR_LATER) { //iOS 9.2 自带滑动返回
        
        SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:url];
        [self presentViewController:sfvc animated:YES completion:NULL];
        
    } else if (IOS9_OR_LATER) {
        
        HPSFSafariViewController *sfvc = [[HPSFSafariViewController alloc] initWithURL:url];
        [self presentViewController:[HPCommon swipeableNVCWithRootVC:sfvc] animated:YES completion:NULL];
        
    } else {
        DZWebBrowser *webBrowser = [[DZWebBrowser alloc] initWebBrowserWithURL:url];
        webBrowser.showProgress = YES;
        webBrowser.allowSharing = YES;
        
        NSLog(@"open browser");
        [self presentViewController:[HPCommon swipeableNVCWithRootVC:webBrowser] animated:YES completion:NULL];
    }
    
    [Flurry logEvent:@"Read OpenUrl" withParameters:@{@"url":url.absoluteString}];
}
@end
