//
//  SDImageCache+URLCache.h
//  HiPDA
//
//  Created by Jichao Wu on 15/5/7.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import <SDImageCache.h>

@interface SDImageCache (URLCache)
//
- (UIImage *)scaledImageForKey:(NSString *)key image:(UIImage *)image;
@property (strong, readonly, nonatomic) NSCache *memCache;
- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key;

//
- (UIImage *)hp_imageWithData:(NSData *)data key:(NSString *)key;
- (NSData *)hp_imageDataFromDiskCacheForKey:(NSString *)key;
@end