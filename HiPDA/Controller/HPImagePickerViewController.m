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
#import "HPQMUIImagePickerViewController.h"

@interface HPImagePickerViewController ()<
QMUIAlbumViewControllerDelegate,
QMUIImagePickerViewControllerDelegate,
QMUIImagePickerPreviewViewControllerDelegate
>

@property (nonatomic, strong) id <HPImagePickerUploadDelegate> uploadDelegate;

@end

@implementation HPImagePickerViewController

+ (void)authorizationPresentAlbumViewController:(UIViewController *)parent
{
    if ([QMUIAssetsManager authorizationStatus] == QMUIAssetAuthorizationStatusNotDetermined) {
        [QMUIAssetsManager requestAuthorization:^(QMUIAssetAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.class presentAlbumViewController:parent];
            });
        }];
    } else {
        [self.class presentAlbumViewController:parent];
    }
}

+ (void)presentAlbumViewController:(UIViewController *)parent
{
    HPImagePickerViewController *albumViewController = [[HPImagePickerViewController alloc] init];
    albumViewController.uploadDelegate = (id<HPImagePickerUploadDelegate>)parent;
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
    
    for (QMUIAsset *asset in imagesAssetArray) {
        [QMUIImagePickerHelper requestImageAssetIfNeeded:asset completion:^(QMUIAssetDownloadStatus downloadStatus, NSError *error) {
            if (downloadStatus == QMUIAssetDownloadStatusDownloading) {
                [SVProgressHUD showWithStatus:@"从 iCloud 加载中..."];
            } else if (downloadStatus == QMUIAssetDownloadStatusSucceed) {
                [weakSelf sendImageWithImagesAssetArrayIfDownloadStatusSucceed:imagesAssetArray];
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
//    [SVProgressHUD dismiss];


    // TODO upload

}


@end
