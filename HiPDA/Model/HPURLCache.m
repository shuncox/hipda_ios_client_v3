//
//  HPURLCache.m
//  HiPDA
//
//  Created by Jichao Wu on 15/5/6.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import "HPURLCache.h"
#import <SDWebImageManager.h>
#import <UIImage+MultiFormat.h>
#import "SDImageCache+URLCache.h"

#if 1
#define NSLog(...) do { } while (0)
#endif

/*
webview 请求一个image
-> 有缓存吗(cachedResponseForRequest)
 -> nil -> get & save it
 -> urlcache mem
 -> sdwebimage (mem/disk)
    source (urlcache/sdwebimage)

    读sdwebimage
    -> mem 无data
    -> disk 有data

-> 存起来(storeCachedResponse:forRequest)
 -> 只有imageData(webview请求得到的)
*/

@interface NSString (hasSuffixes)
- (BOOL)hasSuffixes:(NSArray *)suffixes;
@end
@implementation NSString (hasSuffixes)
- (BOOL)hasSuffixes:(NSArray *)suffixes
{
    __block BOOL f = NO;
    [suffixes enumerateObjectsUsingBlock:^(NSString *suffix, NSUInteger idx, BOOL *stop) {
        if ([self hasSuffix:suffix]) {
            f = YES;
            *stop = YES;
        }
    }];
    return f;
}
@end

@implementation HPURLCache

#pragma mark - NSURLCache

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request
{
    if (![self shouldCache:request]) {
        NSLog(@"should not cache %@ %@", request.URL, @(request.cachePolicy));
        return [super cachedResponseForRequest:request];
    }

    NSLog(@"cachedResponseForRequest for %@ %@", request.URL, @(request.cachePolicy));
    NSCachedURLResponse *memoryResponse = [super cachedResponseForRequest:request];
    if (memoryResponse) {
        NSLog(@"memoryResponse");
        return memoryResponse;
    }

    __block NSCachedURLResponse *cachedResponse = nil;
    dispatch_sync(get_disk_cache_queue(), ^{

        NSString *cacheKey = [[self class] cacheKeyForURL:request.URL];
        UIImage *memCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:cacheKey];
        NSData *data = nil;
        if (memCachedImage) {
            NSLog(@"get memcache");
            // 无法从uiimage 判断jpeg png gif, 所以俺jpeg处理
            if (!memCachedImage.images) {
                data = UIImageJPEGRepresentation(memCachedImage, 1.f);
            } else {
                data = nil;
                //data = UIImageJPEGRepresentation(memCachedImage, 1.f);
                /*
                 效率太差
                data = [AnimatedGIFImageSerialization animatedGIFDataWithImage:memCachedImage
                                                                      duration:1.0
                                                                     loopCount:1
                                                                         error:nil];
                 */
            }
        } else {
            NSLog(@"get disk cache");
            data = [[SDImageCache sharedImageCache] hp_imageDataFromDiskCacheForKey:cacheKey];
        }

        if (data) {
            //https://github.com/evermeer/EVURLCache/blob/master/EVURLCache.m:87
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"cache" expectedContentLength:[data length] textEncodingName:nil] ;
            cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
        } else {
            NSLog(@"not get cachedImage");
        }
    });

    return cachedResponse;
}

/*
 http://stackoverflow.com/questions/9039144/uiwebview-doesnt-always-call-nsurlcache-storecachedresponseforrequest/9900008#9900008
 
 NSURLConnection doesn't even call storeCachedResponse:forRequest: for files over about 50KB (>= 52428 bytes, to be exact).
*/
- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
    if ([self shouldCache:request]) {

        NSLog(@"storeCachedResponse %@", request.URL);

        /*
        UIImage *image = [[UIImage alloc] initWithData:cachedResponse.data];
        [[SDWebImageManager sharedManager] saveImageToCache:image forURL:request.URL];
        */

        dispatch_async(get_disk_io_queue(), ^{
            NSString *cacheKey = [self.class cacheKeyForURL:request.URL];
            UIImage *image = [[[SDWebImageManager sharedManager] imageCache] hp_imageWithData:cachedResponse.data key:cacheKey];
            if (image) {
                [[[SDWebImageManager sharedManager] imageCache] storeImage:image recalculateFromImage:NO imageData:cachedResponse.data forKey:cacheKey toDisk:YES];
            } else {
                //404, ...
            }
        });
        
        return;
    }
    [super storeCachedResponse:cachedResponse forRequest:request];
}

- (void)removeCachedResponseForRequest:(NSURLRequest *)request
{

    [super removeCachedResponseForRequest:request];
}

- (void)removeAllCachedResponses
{

    [super removeAllCachedResponses];
}

#pragma mark -

static dispatch_queue_t get_disk_cache_queue()
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t _diskCacheQueue;
    dispatch_once(&onceToken, ^{
        _diskCacheQueue = dispatch_queue_create("com.jichaowu.disk-cache.processing", NULL);
    });
    return _diskCacheQueue;
}

static dispatch_queue_t get_disk_io_queue() {
    static dispatch_queue_t _diskIOQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _diskIOQueue = dispatch_queue_create("com.jichaowu.disk-cache.io", NULL);
        
        // set priority
        dispatch_queue_t globalLowQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_set_target_queue(_diskIOQueue, globalLowQueue);
    });
    return _diskIOQueue;
}

- (BOOL)shouldCache:(NSURLRequest *)request
{
    return NO;
    if (request.cachePolicy != NSURLRequestReloadIgnoringLocalCacheData
        && [[request.URL absoluteString] hasSuffixes:@[@".jpg", @".jpeg", @".gif", @".png"]]) {
        return YES;
    }

    return NO;
}

+ (NSString *)cacheKeyForURL:(NSURL *)url {
    return [[SDWebImageManager sharedManager] cacheKeyForURL:url];
}

@end
