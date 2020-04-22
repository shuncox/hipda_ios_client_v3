//
//  HPPDFPreviewViewController.m
//  HiPDA
//
//  Created by Jiangfan on 2017/6/10.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "HPPDFPreviewViewController.h"
#import <WebKit/WebKit.h>

@interface HPPDFPreviewViewController ()

@property (nonatomic, strong) NSData *pdfData;
@property (nonatomic, strong) WKWebView *webView;

@end

@implementation HPPDFPreviewViewController

+ (void)presentInViewController:(UIViewController *)viewController
                        pdfData:(NSData *)pdfData
{
    HPPDFPreviewViewController *vc = [HPPDFPreviewViewController new];
    vc.pdfData = pdfData;
    [viewController presentViewController:[HPCommon swipeableNVCWithRootVC:vc]
                                 animated:YES
                               completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.webView = [WKWebView new];
    [self.view addSubview:self.webView];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    
    [self.webView loadData:self.pdfData
                  MIMEType:@"application/pdf"
     characterEncodingName:@"UTF-8"
                   baseURL:nil];
    
    self.title = @"导出PDF";
    
    UIBarButtonItem *closeButtonItem = [
                                        [UIBarButtonItem alloc] initWithTitle:@"完成"
                                        style:UIBarButtonItemStylePlain
                                        target:self action:@selector(close:)];
    self.navigationItem.leftBarButtonItem = closeButtonItem;
    
    UIBarButtonItem *shareButtonItem = [
                                        [UIBarButtonItem alloc] initWithTitle:@"分享"
                                        style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(share:)];
    self.navigationItem.rightBarButtonItem = shareButtonItem;
}

- (void)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)share:(id)sender
{
    NSCParameterAssert(self.pdfData);
    if (!self.pdfData) {
        return;
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.pdfData] applicationActivities:nil];
    
    if (IS_IPAD && IOS8_OR_LATER) {
        activityViewController.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems[0];
    }
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

@end
