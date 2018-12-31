//
//  HPImagePickerViewController.m
//  HiPDA
//
//  Created by Jichao Wu on 15-1-5.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import "HPImagePickerViewController.h"
#import "SVProgressHUD.h"
#import <QMUIKit/QMUIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "HPQMUIImagePickerViewController.h"
#import "UIImage+Resize.h"
#import "HPSendPost.h"
#import "HPQCloudUploader.h"

@class image;

@interface HPImagePickerViewController ()<
QMUIAlbumViewControllerDelegate,
QMUIImagePickerViewControllerDelegate,
QMUIImagePickerPreviewViewControllerDelegate
>

@property (nonatomic, strong) id <HPImagePickerUploadDelegate> uploadDelegate;
@property (nonatomic, assign) BOOL useQiniu;
@property (nonatomic, strong) HPQMUIImagePickerViewController *imagePickerViewController;

@end

@implementation HPImagePickerViewController

+ (void)load
{
    UIColor *tintColor = UIColorMake(0, 110, 230);
    QMUICMI.buttonTintColor = tintColor;
    UIImage *checkboxImage = [QMUIHelper imageWithName:@"QMUI_pickerImage_checkbox"];
    UIImage *checkboxCheckedImage = [QMUIHelper imageWithName:@"QMUI_pickerImage_checkbox_checked"];
    [QMUIImagePickerCollectionViewCell appearance].checkboxImage = [checkboxImage qmui_imageWithTintColor:tintColor];
    [QMUIImagePickerCollectionViewCell appearance].checkboxCheckedImage = [checkboxCheckedImage qmui_imageWithTintColor:tintColor];
}

+ (void)authorizationPresentAlbumViewController:(UIViewController *)parent
                                       delegate:(id<HPImagePickerUploadDelegate>)delegate
                                         qcloud:(BOOL)qcloud;
{
    if ([QMUIAssetsManager authorizationStatus] == QMUIAssetAuthorizationStatusNotDetermined) {
        [QMUIAssetsManager requestAuthorization:^(QMUIAssetAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.class presentAlbumViewController:parent delegate:delegate qcloud:qcloud];
            });
        }];
    } else {
        [self.class presentAlbumViewController:parent delegate:delegate qcloud:qcloud];
    }
}

+ (void)presentAlbumViewController:(UIViewController *)parent
                          delegate:(id<HPImagePickerUploadDelegate>)delegate
                            qcloud:(BOOL)qcloud
{
    HPImagePickerViewController *albumViewController = [[HPImagePickerViewController alloc] init];
    albumViewController.uploadDelegate = delegate;
    albumViewController.useQiniu = qcloud;
    QMUINavigationController *navigationController = [[QMUINavigationController alloc] initWithRootViewController:albumViewController];

    // 获取最近发送图片时使用过的相簿，如果有则直接进入该相簿  (必须在已经有navigationController后调用)
    [albumViewController pickLastAlbumGroupDirectlyIfCan];

    [parent presentViewController:navigationController animated:YES completion:NULL];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.albumViewControllerDelegate = self;
        self.contentType = QMUIAlbumContentTypeOnlyPhoto;
        self.title = @"图片上传";
    }
    return self;
}

#pragma mark - <QMUIAlbumViewControllerDelegate>

- (QMUIImagePickerViewController *)imagePickerViewControllerForAlbumViewController:(QMUIAlbumViewController *)albumViewController {
    QMUIImagePickerViewController *imagePickerViewController = [[HPQMUIImagePickerViewController alloc] init];
    imagePickerViewController.imagePickerViewControllerDelegate = self;
    return imagePickerViewController;
}

#pragma mark - <QMUIImagePickerViewControllerDelegate>

- (void)imagePickerViewController:(QMUIImagePickerViewController *)imagePickerViewController didFinishPickingImageWithImagesAssetArray:(NSMutableArray<QMUIAsset *> *)imagesAssetArray {
    // 储存最近选择了图片的相册，方便下次直接进入该相册
    [QMUIImagePickerHelper updateLastestAlbumWithAssetsGroup:imagePickerViewController.assetsGroup ablumContentType:QMUIAlbumContentTypeOnlyPhoto userIdentify:nil];
    
    [self sendImageWithImagesAssetArray:imagesAssetArray];
}

- (QMUIImagePickerPreviewViewController *)imagePickerPreviewViewControllerForImagePickerViewController:(QMUIImagePickerViewController *)imagePickerViewController
{
    QMUIImagePickerPreviewViewController *imagePickerPreviewViewController = [[QMUIImagePickerPreviewViewController alloc] init];
    imagePickerPreviewViewController.delegate = self;
    return imagePickerPreviewViewController;
}

#pragma mark - 业务方法

- (void)sendImageWithImagesAssetArray:(NSMutableArray<QMUIAsset *> *)imagesAssetArray {
    __weak __typeof(self)weakSelf = self;
    __block int count = imagesAssetArray.count;
    for (QMUIAsset *asset in imagesAssetArray) {
        [QMUIImagePickerHelper requestImageAssetIfNeeded:asset completion:^(QMUIAssetDownloadStatus downloadStatus, NSError *error) {
            if (downloadStatus == QMUIAssetDownloadStatusDownloading) {
                [SVProgressHUD showWithStatus:@"从 iCloud 加载中..."];
            } else if (downloadStatus == QMUIAssetDownloadStatusSucceed) {
                if (--count == 0) {
                    [weakSelf sendImageWithImagesAssetArrayIfDownloadStatusSucceed:imagesAssetArray];
                }
            } else {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"iCloud 下载错误 (%@)", error.localizedDescription]];
            }
        }];
    }
}

- (void)sendImageWithImagesAssetArrayIfDownloadStatusSucceed:(NSMutableArray<QMUIAsset *> *)imagesAssetArray {
    if (![QMUIImagePickerHelper imageAssetsDownloaded:imagesAssetArray]) {
        return;
    }

    [SVProgressHUD showWithStatus:@"" maskType:SVProgressHUDMaskTypeBlack];

    if (self.imagePickerViewController.selectedImageAssetArray.count <= 0) {
        [SVProgressHUD showErrorWithStatus:@"还没选呢"];
        return;
    }

    [self uploadImage:0];
}


- (void)uploadDone {
    [SVProgressHUD dismiss];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)uploadImage:(NSUInteger)index {

    NSMutableArray<QMUIAsset *> *assets = self.imagePickerViewController.selectedImageAssetArray;
    int count = assets.count;

    __weak typeof(self) weakSelf = self;
    [self uploadAsset:assets[index] progressBlock:^(NSString *progress) {
        NSString *current = [NSString stringWithFormat:@"(%@/%@)", @(index+1), @(assets.count)];
        [SVProgressHUD showWithStatus:S(@"%@ %@", current, progress) maskType:SVProgressHUDMaskTypeBlack];
    } block:^(NSString *attach, NSError *error) {
        if (!error) {
            [weakSelf.uploadDelegate completeWithAttachString:attach error:nil];
            if (index+1 < count) {
                [weakSelf uploadImage:index+1];
            } else {
                [weakSelf uploadDone];
            }
        } else {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
            weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
        }
    }];
}

- (void)uploadAsset:(QMUIAsset *)imageAsset
      progressBlock:(void (^)(NSString *progress))progressBlock
              block:(void (^)(NSString *attach, NSError *error))block {

    progressBlock(@"压缩中...");
    NSLog(@"compress...");

    [imageAsset requestImageData:^(NSData *imageData, NSDictionary<NSString *,id> *info, BOOL isGif, BOOL isHEIC) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *targetImage = nil;
            if (isGif) {
                targetImage = [UIImage qmui_animatedImageWithData:imageData];
            } else {
                targetImage = [UIImage imageWithData:imageData];
                if (isHEIC) {
                    // iOS 11 中新增 HEIF/HEVC 格式的资源，直接发送新格式的照片到不支持新格式的设备，照片可能会无法识别，可以先转换为通用的 JPEG 格式再进行使用。
                    // 详细请浏览：https://github.com/QMUI/QMUI_iOS/issues/224
                    targetImage = [UIImage imageWithData:UIImageJPEGRepresentation(targetImage, 1)];
                }
            }


            // 压缩
            NSData *uploadData = imageData;
            if (!isGif) {
                CGFloat targetSize = MIN(
                    MIN(targetImage.size.width, targetImage.size.height),
                    self.imagePickerViewController.targetSize * SP_SCREEN_SCALE()
                );
                targetImage = [targetImage resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(targetSize, targetSize) interpolationQuality:kCGInterpolationDefault];
                uploadData = UIImageJPEGRepresentation(targetImage, 0.5);
            }
            NSParameterAssert(uploadData);

            // 文件尺寸: 小于 976KB
            // 可用扩展名: jpg, jpeg, gif, png, bmp

            NSInteger size = uploadData.length/1024;
            NSLog(@"compress done %@", @(size));

            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"upload....");
                progressBlock([NSString stringWithFormat:@"上传中...(0/%@kb)", @(size)]);

                [self uploadImage:uploadData
                        imageName:isGif?@"_.gif":nil
                         mimeType:isGif?@"image/gif":nil
                    progressBlock:^(CGFloat progress) {
                        progressBlock([NSString stringWithFormat:@"上传中...(%d/%@kb)", (int)(progress*size), @(size)]);
                    }
                            block:^(NSString *attach, NSError *error) {
                                NSLog(@"attach %@, error %@", attach, [error localizedDescription]);
                                block(attach, error);
                            }];
            });
        });
    }];
}

- (void)uploadImage:(NSData *)imageData
          imageName:(NSString *)imageName
           mimeType:(NSString *)mimeType
      progressBlock:(void (^)(CGFloat progress))progressBlock
              block:(void (^)(NSString *attach, NSError *error))block {
    if (!self.useQiniu) {
        [HPSendPost uploadImage:imageData
                      imageName:nil
                       mimeType:mimeType
                  progressBlock:progressBlock
                          block:block];
    } else {
        [HPQCloudUploader updateImage:imageData
                        progressBlock:progressBlock
                      completionBlock:block];
    }
}

@end
