//
//  HPQCloudUploader.h
//  HiPDA
//
//  Created by Jiangfan on 2018/10/27.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPQCloudUploader : NSObject

+ (void)updateImage:(NSData *)imageData
      progressBlock:(void (^)(CGFloat progress))progressBlock
    completionBlock:(void (^)(NSString *key, NSError *error))completionBlock;

@end
