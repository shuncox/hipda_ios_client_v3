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

//#define NSLog(...) do { } while (0)

static NSString *const HPHTTPURLProtocolHandledKey = @"HPHTTPURLProtocolHandledKey";

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
    [self.class registerURLProtocol];
}

+ (void)registerURLProtocol {
    [NSURLProtocol registerClass:self];
}

- (void)dealloc
{
    if (IOS8_OR_LATER && !IOS9_OR_LATER) {
        if (self.URLConnection) {
            [self.URLConnection cancel];
            [self.URLConnection setValue:nil forKeyPath:@"_internal._delegate"];
            self.URLConnection = nil;
        }
    }
}

- (NSURLRequest *)modifiedRequestWithOriginalRequest:(NSURLRequest *)request {
    NSURL *requestURL = request.URL;
    NSMutableURLRequest *modifiedRequest = request.mutableCopy;
    
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
    
    NSLog(@"canInit NO");
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading
{
    if (![self.class shouldCache:self.request]) {
        [self sendRequest];
        return;
    }
    
    @weakify(self);
    NSString *cacheKey = [[self class] cacheKeyForURL:self.request.URL];
    // 根据苹果CustomHTTPProtocol的thread notes
    // self.client URLProtocolDidFinishLoading: 等方法
    // 需要在client的线程里调用
    [[SDImageCache sharedImageCache] hp_queryImageDataFromCacheForKey:cacheKey
                                                           scheduleOn:[NSThread currentThread]
                                                           completion:^(NSData *data, SDImageCacheType cacheType)
    {
        @strongify(self);
        if (!data) {
            NSLog(@"not get cachedImage");
            [self sendRequest];
            return;
        }
        
        if (cacheType == SDImageCacheTypeMemory) {
            NSLog(@"get memcache %@", self.request);
        } else {
            NSLog(@"get disk cache %@", self.request);
        }
        
        // 直接用缓存完成请求
        //
        //https://github.com/evermeer/EVURLCache/blob/master/EVURLCache.m:87
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:@"cache" expectedContentLength:[data length] textEncodingName:nil] ;
        
        if (0) {
            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
            //https://github.com/buzzfeed/mattress/blob/master/Source/URLProtocol.swift#L195
            [self.client URLProtocol:self cachedResponseIsValid:cachedResponse];
        } else {
            //另一种实现
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [self.client URLProtocol:self didLoadData:data];
            [self.client URLProtocolDidFinishLoading:self];
        }
    }];
}

- (void)stopLoading {
    [self.URLConnection cancel];
    if (IOS8_OR_LATER && !IOS9_OR_LATER) {
        [self.URLConnection setValue:nil forKeyPath:@"_internal._delegate"];
    }
    self.URLConnection = nil;
}

#pragma mark -
- (void)sendRequest
{
//    An NSURLConnections created with the
//    +connectionWithRequest:delegate: or -initWithRequest:delegate:
//    methods are scheduled on the current runloop immediately, and
//    it is not necessary to send the -start message to begin the
//    resource load.<p>
    self.URLConnection = [NSURLConnection connectionWithRequest:[self modifiedRequestWithOriginalRequest:self.request] delegate:self];
    NSLog(@"startLoading %@", self.URLConnection);
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
        
        NSString *cacheKey = [self.class cacheKeyForURL:self.request.URL];
        [[[SDWebImageManager sharedManager] imageCache] hp_storeImageData:self.data forKey:cacheKey];
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
        && [[[request.URL absoluteString] lowercaseString] hasSuffixes:@[@".jpg", @".jpeg", @".gif", @".png", HP_CDN_URL_SUFFIX]]) {
        
        return YES;
    }
    
    return NO;
}

+ (NSString *)cacheKeyForURL:(NSURL *)url {
    return [[SDWebImageManager sharedManager] cacheKeyForURL:url];
}

@end
