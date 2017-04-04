//
//  SDImageCache+URLCache.h
//  HiPDA
//
//  Created by Jichao Wu on 15/5/7.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import <SDImageCache.h>
#import <BlocksKit/NSObject+BKAssociatedObjects.h>

typedef void (^HPImageCacheCompletionBlock)(NSData *data, SDImageCacheType cacheType);

@interface SDImageCache (URLCache)

// public
- (UIImage *)scaledImageForKey:(NSString *)key image:(UIImage *)image;
@property (strong, readonly, nonatomic) NSCache *memCache;
- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key;
@property (SDDispatchQueueSetterSementics, readonly, nonatomic) dispatch_queue_t ioQueue;

// additions
- (BOOL)hp_imageExistsWithKey:(NSString *)key;

- (void)hp_queryImageDataFromCacheForKey:(NSString *)key
                              scheduleOn:(NSThread *)thread
                              completion:(HPImageCacheCompletionBlock)block;

- (void)hp_storeImageData:(NSData *)data
                   forKey:(NSString *)key;

@end
