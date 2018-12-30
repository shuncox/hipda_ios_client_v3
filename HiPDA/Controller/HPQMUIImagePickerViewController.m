//
// Created by Jiangfan on 2018/12/30.
// Copyright (c) 2018 wujichao. All rights reserved.
//

#import "HPQMUIImagePickerViewController.h"

@implementation HPQMUIImagePickerViewController

- (void)handleSendButtonClick:(id)sender
{
    if (self.imagePickerViewControllerDelegate && [self.imagePickerViewControllerDelegate respondsToSelector:@selector(imagePickerViewController:didFinishPickingImageWithImagesAssetArray:)]) {
        [self.imagePickerViewControllerDelegate imagePickerViewController:self didFinishPickingImageWithImagesAssetArray:self.selectedImageAssetArray];
    }
}

@end