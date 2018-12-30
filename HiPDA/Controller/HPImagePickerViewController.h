//
//  HPImagePickerViewController.h
//  HiPDA
//
//  Created by Jichao Wu on 15-1-5.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import "QMUIAlbumViewController.h"

@protocol HPImagePickerUploadDelegate <NSObject>
@required
- (void)completeWithAttachString:(NSString *)string error:(NSError *)error;
@end

@interface HPImagePickerViewController : QMUIAlbumViewController

+ (void)authorizationPresentAlbumViewController:(UIViewController *)parent;

@end
