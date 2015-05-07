//
//  SDImageCache+URLCache.m
//  HiPDA
//
//  Created by Jichao Wu on 15/5/7.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import "SDImageCache+URLCache.h"
#import <UIImage+MultiFormat.h>
#import <SDWebImageDecoder.h>

@implementation SDImageCache (URLCache)

- (NSData *)hp_imageDataFromDiskCacheForKey:(NSString *)key {

    NSData *data = [self diskImageDataBySearchingAllPathsForKey:key];
    UIImage *diskImage = [self hp_imageWithData:data key:key];

    if (diskImage) {
        CGFloat cost = diskImage.size.height * diskImage.size.width * diskImage.scale;
        [self.memCache setObject:diskImage forKey:key cost:cost];
    }

    return data;
}

- (UIImage *)hp_imageWithData:(NSData *)data key:(NSString *)key
{
    UIImage *image = [UIImage sd_imageWithData:data];
    image = [self scaledImageForKey:key image:image];
    image = [UIImage decodedImageWithImage:image];
    return image;
}

@end
