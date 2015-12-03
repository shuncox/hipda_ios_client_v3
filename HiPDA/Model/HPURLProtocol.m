//
//  HPURLProtocol.m
//  HiPDA
//
//
//  https://github.com/JaviSoto/JSTAPIToolsURLProtocol
//

#import "HPURLProtocol.h"
#import "HPSetting.h"
#import <SDWebImageManager.h>
#import <UIImage+MultiFormat.h>
#import "SDImageCache+URLCache.h"
#import "UMOnlineConfig.h"

NSString *HP_WWW_BASE_IP;
NSString *HP_CNC_BASE_IP;

static NSString *const HPHTTPURLProtocolHandledKey = @"HPHTTPURLProtocolHandledKey";

@interface HPURLMappingProvider : NSObject <HPURLMapping>

@end

@implementation HPURLMappingProvider
- (NSString *)apiToolsHostForOriginalURLHost:(NSString *)originalURLHost {
    static NSDictionary *URLMappingDitionary = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        HP_WWW_BASE_IP = [UMOnlineConfig getConfigParams:@"www_ip"] ?: @"58.215.45.20";
        HP_CNC_BASE_IP = [UMOnlineConfig getConfigParams:@"cnc_ip"] ?: @"58.215.45.20";
    
        URLMappingDitionary = @{
                                HP_WWW_BASE_URL : HP_WWW_BASE_IP,
                                HP_CNC_BASE_URL : HP_CNC_BASE_IP
                                };
    });
    
    return URLMappingDitionary[originalURLHost];
}
@end


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

@interface HPURLProtocol () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *URLConnection;
@property (nonatomic, strong) NSMutableData *data;

@end

static id<HPURLMapping> s_URLMapping;

@implementation HPURLProtocol

#pragma mark - 替换url相关
+ (void)registerURLProtocolIfNeed {
    [NSURLProtocol unregisterClass:self];
    if ([Setting boolForKey:HPSettingForceDNS]) {
        [self.class registerURLProtocol];
    }
}

+ (void)registerURLProtocol {
    return [self.class registerURLProtocolWithURLMapping:[HPURLMappingProvider new]];
}

+ (void)registerURLProtocolWithURLMapping:(id<HPURLMapping>)URLMapping {
    //NSAssert(!s_URLMapping, @"You can only invoke -%@ once.", NSStringFromSelector(_cmd));
    
    s_URLMapping = URLMapping;
    
    [NSURLProtocol registerClass:self];
}

- (NSURLRequest *)modifiedRequestWithOriginalRequest:(NSURLRequest *)request {
    NSURL *requestURL = request.URL;
    NSMutableURLRequest *modifiedRequest = request.mutableCopy;
    
    // 替换url
    NSString *newHost = [s_URLMapping apiToolsHostForOriginalURLHost:requestURL.host];
    if (newHost) {
        modifiedRequest.URL = [NSURL URLWithString:[requestURL.absoluteString stringByReplacingOccurrencesOfString:requestURL.host withString:newHost]];
        if (![request.allHTTPHeaderFields objectForKey:@"host"]) {
            NSMutableDictionary *d = [request.allHTTPHeaderFields mutableCopy];
            [d setObject:requestURL.host forKey:@"host"];
            modifiedRequest.allHTTPHeaderFields = d;
        }
    }
    
    // 防止递归
    [NSURLProtocol setProperty:@YES forKey:HPHTTPURLProtocolHandledKey inRequest:modifiedRequest];
    
    return modifiedRequest;
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *protocol = request.URL.scheme;
    
    NSLog(@"canInit %@", request.URL);
    
    if (![@[@"http", @"https"] containsObject:protocol]) {
        NSLog(@"not http(s) -> NO");
        return NO;
    }
    
    if ([NSURLProtocol propertyForKey:HPHTTPURLProtocolHandledKey inRequest:request]) {
        NSLog(@"duplicate -> NO");
        return NO;
    }
    
    if ([self.class shouldCache:request]) {
        NSLog(@"image -> YES");
        return YES;
    }
    
    if ([s_URLMapping apiToolsHostForOriginalURLHost:request.URL.host] != nil) {
        NSLog(@"dns -> YES");
        return YES;
    }
    
    NSLog(@"NO");
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    
    // 如果缓存命中, 直接返回缓存
    if ([self.class shouldCache:self.request]) {
        
        NSString *cacheKey = [[self class] cacheKeyForURL:self.request.URL];
        UIImage *memCachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:cacheKey];
        NSData *data = nil;
        if (memCachedImage) {
            NSLog(@"get memcache %@", self.request);
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
            data = [[SDImageCache sharedImageCache] hp_imageDataFromDiskCacheForKey:cacheKey];
            if (data) { NSLog(@"get disk cache %@", self.request); }
        }
        
        if (data) {
            
            // 直接用缓存完成请求
            //
            //https://github.com/evermeer/EVURLCache/blob/master/EVURLCache.m:87
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:@"cache" expectedContentLength:[data length] textEncodingName:nil] ;
            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
            //https://github.com/buzzfeed/mattress/blob/master/Source/URLProtocol.swift#L195
            [self.client URLProtocol:self cachedResponseIsValid:cachedResponse];
            //另一种实现
            /*
             [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
             [self.client URLProtocol:self didLoadData:data];
             [self.client URLProtocolDidFinishLoading:self];
             */
            
            // 结束
            //
            return;
        } else {
            NSLog(@"not get cachedImage");
        }
    }
    
    // 置换请求(域名->ip)
    self.URLConnection = [NSURLConnection connectionWithRequest:[self modifiedRequestWithOriginalRequest:self.request] delegate:self];
    
    NSLog(@"startLoading %@", self.URLConnection);
}

- (void)stopLoading {
    [self.URLConnection cancel];
    self.URLConnection = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    if ([self.class shouldCache:self.request]
        && [response isKindOfClass:NSHTTPURLResponse.class] && [(NSHTTPURLResponse *)response statusCode] == 200) {
        self.data = [[NSMutableData alloc] init];
    } else {
        self.data = nil;
        
        // 404的用户头像特殊处理: 加一个透明的头像到缓存
        if ([response isKindOfClass:NSHTTPURLResponse.class] && [(NSHTTPURLResponse *)response statusCode] == 404
            && [[self.request.URL absoluteString] rangeOfString:@"uc_server/data/avatar"].location != NSNotFound) {
            [[SDImageCache sharedImageCache] storeImage:[UIImage imageNamed:@"clear_color"] forKey:[self.class cacheKeyForURL:self.request.URL]];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    
    if (self.data && [self.class shouldCache:self.request]) {
        [self.data appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    
    // 缓存图片
    if ([self.class shouldCache:self.request]) {
        
        NSLog(@"storeCachedResponse %@", self.request.URL);
        if ([self.data length] == 0) {
            NSLog(@"self.data.length = 0");
            return;
        }
        /*
         UIImage *image = [[UIImage alloc] initWithData:cachedResponse.data];
         [[SDWebImageManager sharedManager] saveImageToCache:image forURL:request.URL];
         */
        NSString *cacheKey = [self.class cacheKeyForURL:self.request.URL];
        UIImage *image = [[[SDWebImageManager sharedManager] imageCache] hp_imageWithData:self.data key:cacheKey];
        if (image) {
            [[[SDWebImageManager sharedManager] imageCache] storeImage:image recalculateFromImage:NO imageData:self.data forKey:cacheKey toDisk:YES];
        } else {
            //404, ...
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

#pragma mark - 图片缓存相关
+ (BOOL)shouldCache:(NSURLRequest *)request
{
    // 1. 如果是SDWebImage的请求, request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData, SDWebImage自己会处理缓存
    // 2. 这里是通过url后缀来判断是不是图片的, 还可以从response.MIMEType
    if (request.cachePolicy != NSURLRequestReloadIgnoringLocalCacheData
        && [[[request.URL absoluteString] lowercaseString] hasSuffixes:@[@".jpg", @".jpeg", @".gif", @".png"]]) {
        
        return YES;
    }
    
    return NO;
}

+ (NSString *)cacheKeyForURL:(NSURL *)url {
    return [[SDWebImageManager sharedManager] cacheKeyForURL:url];
}

@end
