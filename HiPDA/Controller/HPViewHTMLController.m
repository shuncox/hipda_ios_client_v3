//
//  HPViewHTMLController.m
//  HiPDA
//
//  Created by Jichao Wu on 16/1/20.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "HPViewHTMLController.h"
#import "NSString+HTML.h"

@implementation HPViewHTMLController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    
    NSString *html = [NSString stringWithFormat:@"<!DOCTYPE html> <html> <head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\" /> <link rel=\"stylesheet\" href=\"http://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.1.0/styles/default.min.css\"> <script src=\"http://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.1.0/highlight.min.js\"></script> <script>hljs.initHighlightingOnLoad();</script> </head> <body> <pre><code class=\"html\"> %@ </code></pre> </body> </html>", [self.html stringByEncodingHTMLEntities:YES]];
    [webView loadHTMLString:html baseURL:nil];
}
@end
