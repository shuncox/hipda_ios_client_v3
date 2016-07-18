//
//  HPUser.m
//  HiPDA
//
//  Created by wujichao on 13-11-11.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPUser.h"
#import "HPHttpClient.h"
#import "NSString+HTML.h"
#import "HPSetting.h"
#import "HPSearch.h"
#import "HPNewPost.h"

@implementation HPUser {
@private
    NSString *_avatarImageURLString;
}

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _uid = [[attributes valueForKeyPath:@"uid"] integerValue];
    _username = [attributes valueForKeyPath:@"username"];
    
    // 在post页面 可以直接获得 avatar url
    // 也可以直接判断是否存在 avatar
    NSString *avatar = [attributes valueForKeyPath:@"avatar"];
    if (avatar) {
        if (![avatar isEqualToString:@"000/00/00/00"]) {
            _avatarImageURLString = [NSString stringWithFormat:@"http://%@/forum/uc_server/data/avatar/%@_avatar_small.jpg", HP_IMG_BASE_URL, avatar];
            _avatarImageURL = [NSURL URLWithString:_avatarImageURLString];
            //NSLog(@"avatar url %@", _avatarImageURL);
        } else {
            _avatarImageURL = nil;
        }
        
    } else {
        
        /*
         http://www.hi-pda.com/forum/uc_server/data/avatar/000/00/53/69_avatar_middle.jpg
         http://www.hi-pda.com/forum/uc_server/data/avatar/000/02/61/71_avatar_middle.jpg
         http://www.hi-pda.com/forum/uc_server/data/avatar/000/22/22/37_avatar_middle.jpg
         
         2013-9-15 最新会员 747004
         */
        
        NSUInteger a, b, c;
        a = _uid / 10000;
        b = _uid % 10000 / 100;
        c = _uid % 100;
        //NSLog(@"%02d/%02d/%02d", a, b, c);
        
        //size [small middle big]
        _avatarImageURLString = [NSString stringWithFormat:@"http://%@/forum/uc_server/data/avatar/000/%02ld/%02ld/%02ld_avatar_small.jpg", HP_IMG_BASE_URL, a, b, c];
        _avatarImageURL = [NSURL URLWithString:_avatarImageURLString];
    }
    
    return self;
}



- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_uid forKey:@"uid"];
    [aCoder encodeObject:_username forKey:@"username"];
    [aCoder encodeObject:_avatarImageURL forKey:@"avatarImageURL"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _uid = [aDecoder decodeIntegerForKey:@"uid"];
        _username = [aDecoder decodeObjectForKey:@"username"];
        _avatarImageURL = [aDecoder decodeObjectForKey:@"avatarImageURL"];
    }
    return self;
}


+ (NSURL *)avatarStringWithUid:(NSInteger)_uid {
    
    if (!_uid) {
        return nil;
    }
    
    NSInteger a, b, c;
    a = _uid / 10000;
    b = _uid % 10000 / 100;
    c = _uid % 100;
    //NSLog(@"%02d/%02d/%02d", a, b, c);
    
    NSString *avatarImageURLString = [NSString stringWithFormat:@"http://%@/forum/uc_server/data/avatar/000/%02ld/%02ld/%02ld_avatar_small.jpg", HP_IMG_BASE_URL, a, b, c];
    return [NSURL URLWithString:avatarImageURLString];
}


+ (void)getUserSpaceDetailsWithUid:(NSInteger)uid
                        orUsername:(NSString *)username
                             block:(void (^)(NSDictionary* dict, NSError *error))block {
    if (uid == 0 && !username) {
        block(nil, [NSError errorWithDomain:@".hi-pda.com" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"uid == 0 && !username"}]);
        return;
    }
    
    NSString *path = nil;
    if (uid != 0) {
        path = S(@"forum/space.php?uid=%d", uid);
    } else {
        path = S(@"forum/space.php?username=%@", username);
    }
    NSLog(@"getUserSpaceDetails %@", path);
    
    
    [[HPHttpClient sharedClient] getPathContent:path parameters:nil success:^(AFHTTPRequestOperation *operation, NSString *html) {
        
    
        NSMutableArray *list = [NSMutableArray arrayWithCapacity:10];
        NSString *_username = @"";
        NSInteger _uid = 0;
        RxMatch *m1 = [RX(@"; (.*?)的个人资料") firstMatchWithDetails:html];
        if (m1) {
            RxMatchGroup *g = [m1.groups objectAtIndex:1];
            _username = (g.value ? g.value : @"");
        }
        RxMatch *m2 = [RX(@"\\(UID: (\\d+)\\)") firstMatchWithDetails:html];
        if (m2) {
            RxMatchGroup *g = [m2.groups objectAtIndex:1];
            _uid = [g.value integerValue];
        }
        
        
        
        //http://www.hi-pda.com/forum/space.php?uid=91718
        NSArray *ms1 = [RX(@"<th[^>]*>(.*?)</th>\r\n<td[^>]*>(?:\r\n)?(.*?)</td>") matchesWithDetails:html];
        
        for (RxMatch *m in ms1) {
            
            RxMatchGroup *g1 = [m.groups objectAtIndex:1];
            RxMatchGroup *g2 = [m.groups objectAtIndex:2];
            
            g1.value = [g1.value stringByReplacingOccurrencesOfString:@":" withString:@""];
            g2.value = [g2.value stringByConvertingHTMLToPlainText];
            
            //NSLog(@"%@_%@", g1.value, g2.value);
            
            NSDictionary *info = @{
                @"key": g1.value ? g1.value:[NSNull null],
                @"value": g2.value ? g2.value:[NSNull null]
            };
            
            [list addObject:info];
        }
        
        NSArray *ms2 = [RX(@"<li>(.*?)</li>") matchesWithDetails:html];
        
        for (RxMatch *m in ms2) {
            
            RxMatchGroup *g1 = [m.groups objectAtIndex:1];
            g1.value = [g1.value stringByConvertingHTMLToPlainText];
            //NSLog(@"%@", g1.value);
            
            if ([g1.value hasPrefix:@"(UID"]) {
                continue;
            }
            
            NSArray *array = [g1.value componentsSeparatedByString:@": "];
            if ([array count] == 2) {
                NSDictionary *info = @{@"key": array[0], @"value": array[1]};
                [list addObject:info];
            } else if ([array count] == 1){
                NSDictionary *info = @{@"key": array[0], @"value": [NSNull null]};
                [list addObject:info];
            }
        }
        
        NSLog(@"%@", @{@"uid": @(_uid), @"username":_username, @"list": list});
       
        block(@{@"uid": @(_uid), @"username":_username, @"list": list}, nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        block(nil, error);
        
    }];
    
}

+ (void)getUserUidWithUserName:(NSString *)username
                         block:(void (^)(NSString *uid, NSError *error))block
{
    [self.class getUserSpaceDetailsWithUid:0 orUsername:username block:^(NSDictionary *dict, NSError *error) {
        if (error) {
            block(nil, error);
            return;
        }
        if ([dict objectForKey:@"uid"]) {
            block([dict objectForKey:@"uid"], nil);
        } else {
            block(nil, [NSError errorWithDomain:@".hi-pda.com" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"没找到uid"}]);
        }
    }];
}
+ (void)getUserSignatureWithUid:(NSString *)uid
                          block:(void (^)(NSString *signature, NSError *error))block
{
    [HPSearch searchWithParameters:@{@"key": uid}
                              type:HPSearchTypeUserTopic
                              page:1
                             block:^(NSArray *results, NSInteger pageCount, NSError *error) {
                                 
                                 if (error) {
                                     block(nil, error);
                                     return;
                                 }
                                 if (!results.count) {
                                     block(nil, [NSError errorWithDomain:@".hi-pda.com" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"没找到帖子"}]);
                                     return;
                                 }
                                 
                                 NSString *tid = [results[0] objectForKey:@"tidString"];
                                 [HPNewPost loadThreadWithTid:[tid integerValue] page:1 forceRefresh:YES printable:NO authorid:0 redirectFromPid:0 block:^(NSArray *posts, NSDictionary *parameters, NSError *error) {
                                     if (error) {
                                         block(nil, error);
                                     }
                                     if (!posts.count) {
                                         block(nil, [NSError errorWithDomain:@".hi-pda.com" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"没找到帖子"}]);
                                         return;
                                     }
                                     HPNewPost *p = posts[0];
                                     block(p.signature, nil);
                                 }];
                             }];
}
@end
