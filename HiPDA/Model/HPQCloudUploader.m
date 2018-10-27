//
//  HPQCloudUploader.m
//  HiPDA
//
//  Created by Jiangfan on 2018/10/27.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPQCloudUploader.h"
#import "NSString+Additions.h"
#import <QCloudCOSXML/QCloudCOSXML.h>

@interface HPQCloudSignatureProvider : NSObject<QCloudSignatureProvider>
@end

@implementation HPQCloudSignatureProvider
/**
 访问腾讯云的服务需要对请求进行签名，以确定访问的用户身份，同时也保障访问的安全性。该函数返回一个基于Bolts-Task的结构，里面包裹着您对请求完成的签名。该函数使用了promise机制，更多信息请参考Bolts的设计。比如您自己搭建了一个用于签名的服务器，然后通过服务器来进行签名：
 
 这里使用Bolts的promise机制时考虑到，您的请求签名过程可能是一个网络过程。该过程将会非常涉及到异步操作，而promise机制可以极大的简化异步编程的复杂度。此处请您一定确保调用task的`setResult`方法或者`setError`方法。将您请求的结果通知到我们，否则后续的请求过程将无法继续。
 @param fileds 进行签名的关键字段
 @param request 需要进行签名的请求
 */
- (void) signatureWithFields:(QCloudSignatureFields*)fileds
                     request:(QCloudBizHTTPRequest*)request
                  urlRequest:(NSMutableURLRequest*)urlRequst
                   compelete:(QCloudHTTPAuthentationContinueBlock)continueBlock
{

}
@end

@implementation HPQCloudUploader

+ (void)updateImage:(NSData *)imageData
      progressBlock:(void (^)(CGFloat progress))progressBlock
    completionBlock:(void (^)(NSString *key, NSError *error))completionBlock
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        QCloudServiceConfiguration* configuration = [QCloudServiceConfiguration new];
        configuration.appID = @"1252000006";
        configuration.signatureProvider = [HPQCloudSignatureProvider new];
        QCloudCOSXMLEndPoint* endpoint = [[QCloudCOSXMLEndPoint alloc] init];
        endpoint.regionName = @"ap-shanghai";//服务地域名称，可用的地域请参考注释
        configuration.endpoint = endpoint;
        
        [QCloudCOSXMLService registerDefaultCOSXMLWithConfiguration:configuration];
        [QCloudCOSTransferMangerService registerDefaultCOSTransferMangerWithConfiguration:configuration];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        QCloudCOSXMLUploadObjectRequest* upload = [QCloudCOSXMLUploadObjectRequest new];
        upload.body = imageData;
        upload.bucket = @"hpimg-1252000006";
        upload.object = [NSUUID UUID].UUIDString;
        upload.accessControlList = @"public-read";
        
        [upload setFinishBlock:^(QCloudUploadObjectResult *result, NSError * error) {
            NSLog(@"upload result:%@, error:%@", result, error);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    completionBlock(nil, error);
                    return;
                }
                completionBlock(result.location, nil);
            });
        }];
        
        [upload setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            NSLog(@"progress %f", (1.0f*totalBytesSent)/totalBytesExpectedToSend);
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock((1.0f*totalBytesSent)/totalBytesExpectedToSend);
            });
        }];
        
        [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:upload];
    });
}
@end
