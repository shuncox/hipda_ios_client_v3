//
//  HPThread.m
//  HiPDA
//
//  Created by wujichao on 13-11-11.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPThread.h"
#import "HPUser.h"
#import "HPAccount.h"
#import "HPCache.h"
#import "HPMessage.h"
#import "HPBlockService.h"
#import "HPDatabase.h"
#import "HPSetting.h"

#import "HPHttpClient.h"
#import "TFHpple.h"
#import "NSString+Additions.h"
#import "NSUserDefaults+Convenience.h"
#import "NSString+HTML.h"
#import "NSRegularExpression+HP.h"
#import <AFHTTPRequestOperation.h>

@implementation HPThread


- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _tid = [[attributes valueForKeyPath:@"tid"] integerValue];
    _title = [attributes valueForKeyPath:@"title"];
    _dateString = [attributes valueForKeyPath:@"date"];
    
    
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-M-d"];
    });
    _date = [dateFormatter dateFromString:_dateString];
    
    
    _user = [[HPUser alloc] initWithAttributes:[attributes valueForKeyPath:@"user"]];
    _replyCount = [[attributes valueForKeyPath:@"replyCount"] integerValue];
    _openCount = [[attributes valueForKeyPath:@"openCount"] integerValue];
    
    _pageCount = _replyCount / 50 + 1;
    
    _hasImage = [[attributes valueForKeyPath:@"hasImage"] boolValue];
    _hasAttach = [[attributes valueForKeyPath:@"hasAttach"] boolValue];
    
    _titleColor = [attributes valueForKeyPath:@"titleColor"];
    
    return self;
}

#pragma mark -

/*
 tid 
 fid
 
 @"title"
 @"titleColor"
 
 @"user":userAttributes
 
 @"date"
 @"replyCount"
 @"openCount"
 
 @"hasImage" @"hasAttach"
*/

+ (void)loadThreadsWithFid:(NSInteger)fid
                      page:(NSInteger)page
              filterParams:(NSDictionary *)filterParams
              forceRefresh:(BOOL)forceRefresh //无用了
                     block:(void (^)(NSArray *posts, NSError *error))block
{
    NSString *path = [NSString stringWithFormat:@"forum/forumdisplay.php?fid=%ld&page=%ld", fid, page];
    BOOL stickthread = NO;
    for (NSString *k in filterParams) {
        NSString *v = filterParams[k];
        if ([v isEqualToString:@"stickthread"]) {
            stickthread = YES;
        }
        else if (v.length) {
            path = [path stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", k, v]];
        }
    }

    NSLog(@"load thread path : %@",path);
    
    [[HPHttpClient sharedClient] getPathContent:path parameters:nil success:^(AFHTTPRequestOperation *operation, NSString *html) {
        
#if DEBUG
        if (0) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"debug_crawler_html" ofType:@"html"];
            NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
            html = content;
        }
#endif

        /*
        NSHTTPURLResponse *response = [operation response];
         NSDictionary *fields = [response allHeaderFields];
         //NSLog(@"%@", fields);
         NSString *cookie = [fields valueForKey:@"Set-Cookie"];
         NSLog(@"response Set-Cookie cookie %@", cookie);
        */
        
        HPCrawlerErrorContext *context = [HPCrawlerErrorContext new];
        context.url = [NSString stringWithFormat:@"%@/%@", HP_BASE_URL, path];
        context.html = html;
        context.requestHeaders = ({
            NSURLRequest *request = [operation request];
            [request allHTTPHeaderFields];
        });
        context.responseHeaders = ({
            NSHTTPURLResponse *response = [operation response];
            [response allHeaderFields];
        });
        context.cookies = ({
            NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
            NSMutableArray *r = [NSMutableArray array];
            for (NSHTTPCookie *c in cookies) {
                if ([c.domain hasSuffix:@".hi-pda.com"]) {
                    [r addObject:c];
                }
            }
            [r copy];
        });
        
        
        if ([html indexOf:@"normalthread_"] == -1 && block) {
            
            NSString *alert_info = [html stringBetweenString:@"<div class=\"alert_info\">" andString:@"</div>"];
            NSString *alert_error = [html stringBetweenString:@"<div class=\"alert_error\">" andString:@"</div>"];
            NSString *msg = nil;
            if (alert_info) msg = alert_info;
            else if (alert_error) msg = alert_error;
            else {
                NSError *e = nil;
                if (msg) {
                    e = [NSError errorWithErrorCode:HPERROR_DISCUZ_ALERT_CODE errorMsg:msg];
                } else if ([html indexOf:@"stickthread_"] != -1) {
                    e = [NSError errorWithErrorCode:HPERROR_NOT_DEFAULT_THREAD_SETTING_CODE errorMsg:html];
                } else {
                    e = [NSError crawlerErrorWithContext:context];
                }
                block([NSArray array], e);
            }
            return;
        }
        
        
        //NSArray *threadsInfo = [HPThread parserHTML:html];
        NSArray *threadsInfo = [HPThread extractThreads:html stickthread:stickthread];
        
        NSMutableArray *threads = [NSMutableArray arrayWithCapacity:[threadsInfo count]];
        for (NSDictionary *attributes in threadsInfo) {
            HPThread *thread = [[HPThread alloc] initWithAttributes:attributes];
            thread.fid = fid;
            
            if ([[HPBlockService shared] isUserInBlockList:thread.user.username]) {
                NSLog(@"block %@, remove it from thread list", thread.user.username);
            } else {
                [threads addObject:thread];
            }
        }
        
        if (threads.count == 0 && !stickthread) {
            block([NSArray array], [NSError crawlerErrorWithContext:context]);
            return;
        }
        
        // update uid database
        [self.class updateUidDatabase:threads];
        
        if (block) {
            block([threads copy], nil);
        }
        
        [self saveUID:html];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:HPLoadThreadListSuccess object:nil];
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block([NSArray array], error);
        }
    }];
}

+ (void)updateUidDatabase:(NSArray *)threads
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *users = [@[] mutableCopy];
        for (HPThread *t in threads) {
            [users addObject:t.user];
        }
        
        [[HPDatabase sharedDb].queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (HPUser *user in users) {
                [db executeUpdate:@"insert OR IGNORE into user (username, uid) values (?, ?)",
                 user.username, @(user.uid)];
            }
        }];
    });
}

+ (void)saveUID:(NSString *)html
{
    NSString *tid = [RX(@"<cite><a href=\"space\\.php\\?uid=(\\d+)[^>]+>[^<]+</a>") firstMatchValue:html];
    if (tid.length) {
        [[NSUserDefaults standardUserDefaults] setObject:tid forKey:kHPAccountUID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

//
//+ (NSArray *)parserHTML:(NSString *)HTML {
//    
//    NSString *pattern = @"<tbody id=\"normalthread_.*?</tbody>";
//    
//    NSRegularExpression *reg =
//    [[NSRegularExpression alloc] initWithPattern:pattern
//                                         options:NSRegularExpressionDotMatchesLineSeparators
//                                           error:nil];
//    
//    NSArray *matches = [reg matchesInString:HTML
//                                    options:0
//                                      range:NSMakeRange(0, [HTML length])];
//    
//    NSMutableArray *threads = [NSMutableArray arrayWithCapacity:[matches count]];
//    
//    NSLog(@"threads matches count %ld", [matches count]);
//    
//    for (NSTextCheckingResult *result in matches) {
//        
//        TFHpple *threadDoc = [[TFHpple alloc]initWithHTMLData:[[HTML substringWithRange:[result range]] dataUsingEncoding:NSUTF8StringEncoding]];
//        
//        NSString *tid = [[threadDoc peekAtSearchWithXPathQuery:@"/html/body/tbody/tr/th/span"] objectForKey:@"id"];
//        tid = [tid substringFromIndex:7];
//        
//        TFHppleElement *titleElement = [threadDoc peekAtSearchWithXPathQuery:@"/html/body/tbody/tr/th/span/a"];
//        NSString *title = [titleElement text];
//        UIColor *titleColor = nil;
//        if ([titleElement objectForKey:@"style"]) {
//            titleColor = [[[titleElement objectForKey:@"style"] stringFromString:@"#"] colorFromHexString];
//        }
//        
//        NSString *date = [[threadDoc peekAtSearchWithXPathQuery:@"/html/body/tbody/tr/td[3]/em"] text];
//        
//        TFHppleElement *usernameElement = [threadDoc peekAtSearchWithXPathQuery:@"/html/body/tbody/tr/td[3]/cite/a"];
//        NSString *uid = [usernameElement objectForKey:@"href"];
//        uid = [uid substringFromIndex:14];
//        NSString *username = [usernameElement text];
//        
//        NSString *replyCount = [[threadDoc peekAtSearchWithXPathQuery:@"/html/body/tbody/tr/td[4]/strong"] text];
//        
//        NSString *openCount = [[threadDoc peekAtSearchWithXPathQuery:@"/html/body/tbody/tr/td[4]/em"] text];
//        
//        // pic or attachment
//        NSString *extraTag;
//        BOOL hasImage = NO, hasAttach = NO;
//        if ((extraTag = [[threadDoc peekAtSearchWithXPathQuery:@"/html/body/tbody/tr/th/img"] objectForKey:@"alt"])) {
//            // 会有 img[1] [2] 等等 我想只有一个 附件 或 图片 标示 就足够了
//            if ([extraTag isEqualToString:@"图片附件"]) {
//                hasImage = YES;//{图片}//1F4F7 //02B50
//                title = [NSString stringWithFormat:@"%@ \U0001F4CE", title];
//            } else if ([extraTag isEqualToString:@"附件"]) {
//                hasAttach = YES;///{别针}
//                title = [NSString stringWithFormat:@"%@ \U0001F4CE", title];
//            }
//            
//            /*
//             <img class="attach" alt="图片附件" src="images/attachicons/image_s.gif">
//             <img class="attach" title="精华 1" alt="精华 1" src="images/default/digest_1.gif">
//             <img class="attach" title="帖子被加分" alt="帖子被加分" src="images/default/agree.gif">
//             
//             <img class="attach" alt="附件" src="images/attachicons/common.gif">
//             */
//        }
//        
//        NSDictionary *userAttributes = @{
//                                         @"uid":uid,
//                                         @"username":username
//                                         };
//        //NSLog(@" %d %d %@ ",hasImage,hasAttach,title );
//        NSDictionary *postAttributes = @{
//                                         @"tid":tid,
//                                         @"title":title,
//                                         @"titleColor":(titleColor?titleColor:[NSNull null]),
//                                         @"date":date,
//                                         @"replyCount":replyCount,
//                                         @"openCount":openCount,
//                                         @"hasImage":(hasImage?@YES:@NO),
//                                         @"hasAttach":(hasAttach?@YES:@NO),
//                                         @"user":userAttributes
//                                         };
//        
//        
//        //NSLog(@"%@", postAttributes);
//        [threads addObject:postAttributes];
//    }
//    
//    return threads;
//}

+ (NSArray *)extractThreads:(NSString *)string
                stickthread:(BOOL)stickthread {
    
    //NSLog(@"html : \n%@", string);
    
    string = [string stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    
    if (stickthread) {
        NSRange range1 = [string rangeOfString:@"stickthread_"];
        NSRange range2 = [string rangeOfString:@"normalthread_"];
        if (range1.location != NSNotFound && range2.location != NSNotFound) {
            string = [string substringWithRange:NSMakeRange(range1.location, range2.location-range1.location)];
        } else {
            string = @"";
        }
    } else {
        NSRange range = [string rangeOfString:@"normalthread_"];
        if (range.location != NSNotFound) {
            string = [string substringFromIndex:range.location];
        }
    }
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"<span id=\"thread_(\\d+)\"><a ([^>]+)>(.*?)</a>(.*?)<a href=\"space\\.php\\?uid=(\\d+)[^>]*\">(.*?)</a>\n</cite>\n<em>([^<]+)</em>\n</td>\n<td class=\"nums\"><strong>(\\d+)</strong>/<em>(\\d+)</em></td>"
                                  options:NSRegularExpressionDotMatchesLineSeparators
                                  error:&error
                                  ];
    
    __block NSMutableArray *threadsArray = [NSMutableArray arrayWithCapacity:42];
    
    [regex enumerateMatchesInString:string
                            options:0
                              range:NSMakeRange(0, string.length)
                         usingBlock:
     ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         
         NSString *tidString = [string  substringWithRange:[result rangeAtIndex:1]];
         NSString *aString = [string  substringWithRange:[result rangeAtIndex:2]];
         NSString *title = [string  substringWithRange:[result rangeAtIndex:3]];
         NSString *otherString = [string  substringWithRange:[result rangeAtIndex:4]];
         NSString *uidString = [string  substringWithRange:[result rangeAtIndex:5]];
         NSString *username = [string  substringWithRange:[result rangeAtIndex:6]];
         NSString *dateString = [string  substringWithRange:[result rangeAtIndex:7]];
         NSString *replyCountString = [string  substringWithRange:[result rangeAtIndex:8]];
         NSString *openCountString = [string  substringWithRange:[result rangeAtIndex:9]];
        /*
         NSDictionary *dict = @{
            @"tidString":tidString,
            @"aString":aString,
            @"title":title,
            @"uidString":uidString,
            @"username":username,
            @"dateString":dateString,
            @"replyCountString":replyCountString,
            @"openCountString":openCountString
         };*/
         
         title = [title stringByDecodingHTMLEntities];
         
         
         NSString *titleColorString = [aString stringBetweenString:@"color: #" andString:@"\""];
         UIColor *titleColor = nil;
         if (titleColorString) {
             titleColor = [titleColorString colorFromHexString];
         }

         BOOL hasImage = NO; BOOL hasAttach = NO;
         if ([otherString indexOf:@"图片附件"] != -1) {
             hasImage = YES;
             title = [NSString stringWithFormat:@"%@ \U0001F4CE", title];
         } else if ([otherString indexOf:@"附件"] != -1) {
             hasAttach = YES;
             title = [NSString stringWithFormat:@"%@ \U0001F4CE", title];
         }
        
         NSDictionary *userAttributes = @{
                                          @"uid":uidString,
                                          @"username":username
                                          };
         //NSLog(@" %d %d %@ ",hasImage,hasAttach,title );
         NSDictionary *postAttributes = @{
                                          @"tid":tidString,
                                          @"title":title,
                                          @"titleColor":(titleColor?titleColor:[NSNull null]),
                                          @"date":dateString,
                                          @"replyCount":replyCountString,
                                          @"openCount":openCountString,
                                          @"hasImage":(hasImage?@YES:@NO),
                                          @"hasAttach":(hasAttach?@YES:@NO),
                                          @"user":userAttributes
                                          };
         
         [threadsArray addObject:postAttributes];
     }];
    
    return threadsArray;
}

- (NSString *)shortDate {
    
    if (!self.date) {
        NSLog(@"error !self.date");
        return @"";
    }
    
    NSString *dateString = nil;
    static NSDateFormatter *formatter;
    static NSDateFormatter *formatter_short;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        formatter_short = [[NSDateFormatter alloc] init];
        [formatter_short setDateFormat:@"MM-dd"];
    });
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                        fromDate:self.date
                                                          toDate:[NSDate date]
                                                         options:0];
    
    NSInteger dayInterval = [components day];
    
    if (dayInterval == 0) {
        dateString = @" 今天";
    } else if (dayInterval == 1) {
        dateString = @" 昨天";
    } else if (dayInterval == 2) {
        dateString = @" 前天";
    } else if (dayInterval < 9) {
        dateString = [NSString stringWithFormat:@"%d天前", (int)dayInterval];
    } else if (dayInterval < 365) {
        dateString = [formatter_short stringFromDate:self.date];
    } else {
        dateString = [formatter stringFromDate:self.date];
    }
    return dateString;
}


#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_tid forKey:@"tid"];
    [aCoder encodeObject:_title forKey:@"title"];
    [aCoder encodeObject:_titleColor forKey:@"titleColor"];
    [aCoder encodeObject:_dateString forKey:@"dateString"];
    [aCoder encodeObject:_date forKey:@"date"];
    [aCoder encodeInteger:_replyCount forKey:@"replyCount"];
    [aCoder encodeInteger:_openCount forKey:@"openCount"];
    
    [aCoder encodeBool:_hasImage forKey:@"hasImage"];
    [aCoder encodeBool:_hasAttach forKey:@"hasAttach"];
    
    [aCoder encodeObject:_user forKey:@"user"];
    
    [aCoder encodeInteger:_pageCount forKey:@"pageCount"];
    [aCoder encodeInteger:_fid forKey:@"fid"];
    [aCoder encodeInteger:_pid forKey:@"pid"];
    
    [aCoder encodeObject:_replyDetail forKey:@"replyDetail"];
    [aCoder encodeObject:_threadLastReplyUsername forKey:@"threadLastReplyUsername"];
    [aCoder encodeObject:_threadLastReplyDateString forKey:@"threadLastReplyDateString"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _tid = [aDecoder decodeIntegerForKey:@"tid"];
        _title = [aDecoder decodeObjectForKey:@"title"];
        _titleColor = [aDecoder decodeObjectForKey:@"titleColor"];
        _dateString = [aDecoder decodeObjectForKey:@"dateString"];
        _date = [aDecoder decodeObjectForKey:@"date"];
        _replyCount = [aDecoder decodeIntegerForKey:@"replyCount"];
        _openCount = [aDecoder decodeIntegerForKey:@"openCount"];
        
        _hasImage = [aDecoder decodeBoolForKey:@"hasImage"];
        _hasAttach = [aDecoder decodeBoolForKey:@"hasAttach"];
        
        _user = [aDecoder decodeObjectForKey:@"user"];
    
        _pageCount = [aDecoder decodeIntegerForKey:@"pageCount"];
        _fid = [aDecoder decodeIntegerForKey:@"fid"];
        _pid = [aDecoder decodeIntegerForKey:@"pid"];
        
        _replyDetail = [aDecoder decodeObjectForKey:@"replyDetail"];
        _threadLastReplyUsername = [aDecoder decodeObjectForKey:@"threadLastReplyUsername"];
        _threadLastReplyDateString = [aDecoder decodeObjectForKey:@"threadLastReplyDateString"];
    }
    return self;
}

- (NSString *)description {
    NSString *r = [NSString stringWithFormat:@"tid: %ld", _tid];
    return r;
}

@end
