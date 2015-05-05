//
//  HPImageMultipleUploadViewController.h
//  HiPDA
//
//  Created by Jichao Wu on 15-1-5.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import "HPViewController.h"
@protocol HPImageUploadDelegate <NSObject>
@required
- (void)completeWithAttachString:(NSString *)string error:(NSError *)error;
@end

@interface HPImageMultipleUploadViewController : HPViewController

@property (nonatomic, strong) id <HPImageUploadDelegate> delegate;
@property (nonatomic, assign) BOOL useQiniu;

@end