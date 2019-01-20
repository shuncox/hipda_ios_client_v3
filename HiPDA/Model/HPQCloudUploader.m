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
#import "HPApi.h"

@interface HPQCloudSignatureProvider : NSObject<QCloudSignatureProvider>
@end

@implementation HPQCloudSignatureProvider
- (void) signatureWithFields:(QCloudSignatureFields*)fileds
                     request:(QCloudPutObjectRequest*)request
                  urlRequest:(NSMutableURLRequest*)urlRequst
                   compelete:(QCloudHTTPAuthentationContinueBlock)continueBlock
{
    [[HPApi instance] request:@"/qcloud/sign"
                       params:@{@"bucketName": request.bucket,
                                @"object": request.object,
                                @"headers": urlRequst.allHTTPHeaderFields}
                  returnClass:nil
                    needLogin:NO]
    .then(^id(NSDictionary *data) {
        NSDate *experationDate = [NSDate dateWithTimeIntervalSinceNow:300];
        QCloudSignature *signature = [[QCloudSignature alloc] initWithSignature:data[@"sign"] expiration:experationDate];
        continueBlock(signature, nil);
        return nil;
    })
    .catch(^(NSError *error) {
        continueBlock(nil, error);
    });
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
        upload.object = [[NSUUID UUID].UUIDString stringByAppendingString:@".jpg"];

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
