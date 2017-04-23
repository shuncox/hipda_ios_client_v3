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

static NSString * const MemCacheSuffix = @".nsdata";

@implementation SDImageCache (URLCache)

/*
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
*/

// 返回YES, 意味着urlprotocol可以拿到缓存
// 但不代表SDWebImage可以拿到缓存, 有可能memory里只有imageData缓存, 但是disk里没有imageData缓存
// 供HTML拼接使用
- (BOOL)hp_imageDataExistsWithKey:(NSString *)key
{
    if ([self _hp_queryImageDataFromMemoryCache:key]) {
        return YES;
    }
    
    return [self diskImageExistsWithKey:key];
}

// 返回YES, 意味着SDWebImage可以拿到缓存
- (BOOL)sd_imageExistsForWithKey:(NSString *)key
{
    if ([self imageFromMemoryCacheForKey:key]) {
        return YES;
    }
    
    return [self diskImageExistsWithKey:key];
}

// 供 NSURLProtocol 使用
// 只提供NSData, 不提供解压后的UIImage
// 先从memCache里取(借用SDWebImaeg的memCache, 但是存NSData, 所以使用不同的key)
// 后从diskCache里取
// 和SDWebimage公用一个diskCache, 方便其他地方使用, 如PhotoBrowser
- (void)hp_queryImageDataFromCacheForKey:(NSString *)key
                              scheduleOn:(NSThread *)thread
                              completion:(HPImageCacheCompletionBlock)block
{
    NSParameterAssert(key.length);
    NSParameterAssert(block);

    if (!key.length || !block) {
        return;
    }
    
    void (^invokeCompletionBlock)(NSData *data, SDImageCacheType type) = ^(NSData *data, SDImageCacheType type){
        [self performSelector:@selector(performBlockHelperFunction:)
                     onThread:thread
                   withObject:@[block, data ?: [NSNull null], @(SDImageCacheTypeMemory)]
                waitUntilDone:NO];
    };
    
    NSData *data = [self _hp_queryImageDataFromMemoryCache:key];
    if (data) {
        invokeCompletionBlock(data, SDImageCacheTypeMemory);
        return;
    }
    
    [self _hp_queryImageDataFromDiskCacheForKey:key completion:^(NSData *data) {
        invokeCompletionBlock(data, SDImageCacheTypeDisk);
    }];
}

// array[0]: block:HPImageCacheCompletionBlock
// array[1]: data:NSData or NSNull
// array[2]: type:SDImageCacheType
- (void)performBlockHelperFunction:(NSArray *)array
{
    HPImageCacheCompletionBlock block = (HPImageCacheCompletionBlock)array[0];
    NSData *data = (NSData *)array[1];
    if ([data isKindOfClass:NSNull.class]) {
        data = nil;
    }
    SDImageCacheType type = (SDImageCacheType)array[2];
    block(data, type);
}

// 供 NSURLProtocol 使用
// 只提供NSData, 不提供解压后的UIImage
// 两级缓存
// 1. 借用SDWebImaeg的memCache, 但是存NSData, 所以使用不同的key)
// 2. diskCache
- (void)hp_storeImageData:(NSData *)data
                   forKey:(NSString *)key
{
    NSParameterAssert(data);
    NSParameterAssert(key.length);
    
    if (!data || !key.length) {
        return;
    }
    
    [self _hp_storeImageDataToMemoryCache:data forKey:key];
    [self _hp_storeImageDataToDiskCache:data forKey:key];
}

#pragma mark - internal

- (void)_hp_storeImageDataToMemoryCache:(NSData *)data
                                 forKey:(NSString *)key
{
    [self.memCache setObject:data
                      forKey:[key stringByAppendingString:MemCacheSuffix]
                        cost:data.length];
}

- (NSData *)_hp_queryImageDataFromMemoryCache:(NSString *)key
{
    return [self.memCache objectForKey:[key stringByAppendingString:MemCacheSuffix]];
}

- (void)_hp_storeImageDataToDiskCache:(NSData *)data
                               forKey:(NSString *)key
{
    // SDImageCache.m:244
    dispatch_async(self.ioQueue, ^{
        NSFileManager *fileManager = [self valueForKey:@"_fileManager"];
        NSParameterAssert(fileManager);
        if (!fileManager) {
            return;
        }
        
        // get cache Path for image key
        NSString *cachePathForKey = [self defaultCachePathForKey:key];
        // transform to NSUrl
        NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey];
        
        [fileManager createFileAtPath:cachePathForKey contents:data attributes:nil];
        
        // disable iCloud backup
        if (self.shouldDisableiCloud) {
            [fileURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        }
    });
}

- (void)_hp_queryImageDataFromDiskCacheForKey:(NSString *)key
                                   completion:(void (^)(NSData *imageData))block
{
    // SDImageCache.m:354
    dispatch_async(self.ioQueue, ^{
        @autoreleasepool {
            NSData *data = [self diskImageDataBySearchingAllPathsForKey:key];
            if (data) {
                [self _hp_storeImageDataToMemoryCache:data forKey:key];
            }
            block(data);
        }
    });
}

@end
