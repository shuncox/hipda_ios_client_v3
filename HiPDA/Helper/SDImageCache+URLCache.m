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
#import <SDWebImage/NSData+ImageContentType.h>

@implementation SDImageCache (URLCache)

- (NSData *)hp_imageDataFromDiskCacheForKey:(NSString *)key {

    NSData *data = [self diskImageDataBySearchingAllPathsForKey:key];
    UIImage *diskImage = nil;

    // gif不就在mem缓存了
    NSString *imageContentType = [NSData sd_contentTypeForImageData:data];
    BOOL isGIF = [imageContentType isEqualToString:@"image/gif"];
    
    if (!isGIF && data && (diskImage = [self hp_imageWithData:data key:key])) {
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

- (BOOL)hp_imageExistsWithKey:(NSString *)key
{
    if ([self imageFromMemoryCacheForKey:key]) {
        return YES;
    }
    
    return [self diskImageExistsWithKey:key];
}
@end
