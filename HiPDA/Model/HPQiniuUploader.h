//
//  HPQiniuUploader.h
//  HiPDA
//
//  Created by Jichao Wu on 15/5/4.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPQiniuUploader : NSObject

+ (void)updateImage:(NSData *)imageData
      progressBlock:(void (^)(CGFloat progress))progressBlock
    completionBlock:(void (^)(NSString *key, NSError *error))completionBlock;

@end
