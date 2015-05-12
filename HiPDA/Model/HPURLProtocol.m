//
//  HPURLProtocol.m
//  HiPDA
//
//
//  https://github.com/JaviSoto/JSTAPIToolsURLProtocol
//

#import "HPURLProtocol.h"

@interface HPURLMappingProvider : NSObject <HPURLMapping>

@end

@implementation HPURLMappingProvider
- (NSString *)apiToolsHostForOriginalURLHost:(NSString *)originalURLHost {
    static NSDictionary *URLMappingDitionary = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        URLMappingDitionary = @{
                                @"www.hi-pda.com" : @"180.153.105.124",
                                @"cnc.hi-pda.com" : @"140.207.217.69"
                                };
    });
    
    return URLMappingDitionary[originalURLHost];
}
@end


@interface HPURLProtocol () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *URLConnection;

@end

static id<HPURLMapping> s_URLMapping;

@implementation HPURLProtocol

+ (void)registerURLProtocol {
    return [self.class registerURLProtocolWithURLMapping:[HPURLMappingProvider new]];
}

+ (void)registerURLProtocolWithURLMapping:(id<HPURLMapping>)URLMapping {
    NSAssert(!s_URLMapping, @"You can only invoke -%@ once.", NSStringFromSelector(_cmd));
    
    s_URLMapping = URLMapping;
    
    [NSURLProtocol registerClass:self];
}

- (NSURLRequest *)modifiedRequestWithOriginalRequest:(NSURLRequest *)request {
    NSURL *requestURL = request.URL;
    
    NSString *newHost = [s_URLMapping apiToolsHostForOriginalURLHost:requestURL.host];
    
    if (!newHost) {
        return request;
    }
    
    NSMutableURLRequest *modifiedRequest = request.mutableCopy;
    modifiedRequest.URL = [NSURL URLWithString:[requestURL.absoluteString stringByReplacingOccurrencesOfString:requestURL.host withString:newHost]];
    
    if (![request.allHTTPHeaderFields objectForKey:@"host"]) {
        NSMutableDictionary *d = [request.allHTTPHeaderFields mutableCopy];
        [d setObject:requestURL.host forKey:@"host"];
        modifiedRequest.allHTTPHeaderFields = d;
    }
    
    return modifiedRequest;
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *protocol = request.URL.scheme;
    
    if (![@[@"http", @"https"] containsObject:protocol]) {
        return NO;
    }
    
    NSString *requestedURLHost = request.URL.host;
    const BOOL mappingForwardsHost = ([s_URLMapping apiToolsHostForOriginalURLHost:requestedURLHost] != nil);
    
    return mappingForwardsHost;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    self.URLConnection = [NSURLConnection connectionWithRequest:[self modifiedRequestWithOriginalRequest:self.request] delegate:self];
}

- (void)stopLoading {
    [self.URLConnection cancel];
    self.URLConnection = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}


@end
