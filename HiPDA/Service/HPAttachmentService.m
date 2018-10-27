//
//  HPAttachmentService.m
//  HiPDA
//
//  Created by Jiangfan on 2018/10/27.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPAttachmentService.h"
#import <AFNetworking/AFNetworking.h>
#import "SVProgressHUD.h"
#import "NSString+Additions.h"

@interface HPAttachmentService()<UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) NSString *url;
@property (nonatomic, weak) UIViewController *parentVC;

@end

@implementation HPAttachmentService
- (instancetype)initWithUrl:(NSString *)url
                   parentVC:(UIViewController *)parentVC
{
    self = [super init];
    if (self) {
        _url = url;
        _parentVC = parentVC;
    }
    return self;
}

- (void)start
{
    [self download];
}

- (void)download
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"attachment_temp_file"];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        [SVProgressHUD showProgress:totalBytesRead*1.0/totalBytesExpectedToRead];
    }];
    
    @weakify(self);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self);
        NSLog(@"Successfully downloaded file to %@", path);
        // get filename
        NSDictionary *headers = operation.response.allHeaderFields;
        NSString *filename = [self.class getFileName:headers];
        if (!filename) {
            [SVProgressHUD showErrorWithStatus:@"文件名解析失败"];
            return;
        }
        // rename temp file
        NSString *path2 = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
        NSError *err = NULL;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path2]) {
            [[NSFileManager defaultManager] removeItemAtPath:path2 error:&err];
        }
        [[NSFileManager defaultManager] moveItemAtPath:path toPath:path2 error:&err];
        if (err) {
            [SVProgressHUD showErrorWithStatus:@"文件名解析失败"];
            return;
        }
        // show file
        [self showPreviewController:path2];
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
    
    [operation start];
}

- (void)showPreviewController:(NSString *)filePath
{
    NSURL *url = [NSURL fileURLWithPath:filePath];
    UIDocumentInteractionController *popup = [UIDocumentInteractionController interactionControllerWithURL:url];
    [popup setDelegate:self];
    BOOL r = [popup presentPreviewAnimated:YES];
    if (!r) {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[@"File", [NSURL fileURLWithPath:filePath]] applicationActivities:nil];
        [self.parentVC presentViewController:activityViewController animated:YES completion:nil];
    }
    NSLog(@"presentPreviewAnimated %@", @(r));
}

+ (NSString *)getFileName:(NSDictionary *)headers
{
    NSString *text = headers[@"Content-Disposition"];
    if (!text || ([text rangeOfString:@"filename"].location == NSNotFound)) {
        return nil;
    }
    NSString *filename = [text stringBetweenString:@"filename=\"" andString:@"\""];
    if (!filename) {
        return nil;
    }
    filename = [self.class gbk2utf8:filename];
    return filename;
}

+ (NSString *)gbk2utf8:(NSString *)s
{
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin1);
    NSData *d = [s dataUsingEncoding:enc];
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *src = [[NSString alloc] initWithData:d encoding:gbkEncoding];
    return src;
}

#pragma mark - UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.parentVC;
}

@end
