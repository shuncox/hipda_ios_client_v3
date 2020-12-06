//
//  HPSearch.m
//  HiPDA
//
//  Created by wujichao on 13-11-22.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPSearch.h"

#import "HPHttpClient.h"
#import <AFHTTPRequestOperation.h>
#import "NSString+Additions.h"

#define DEBUG_Search 0


@implementation HPSearch


+ (void)searchWithParameters:(NSDictionary *)parameters
                        type:(HPSearchType)type
                        page:(NSInteger)page
                       block:(void (^)(NSArray *results, NSInteger pageCount,NSError *error))block
{
    static NSInteger searchid = 0;
    
    NSString *path = nil;
    switch (type) {
        case HPSearchTypeTitle:
        {
            NSString *key = [parameters objectForKey:@"key"];
            NSString *random = [parameters objectForKey:@"random"];
            path = [NSString stringWithFormat:@"forum/search.php?srchtxt=%@&srchtype=%@&searchsubmit=true&st=on&srchuname=&srchfilter=all&srchfrom=0&before=&orderby=lastpost&ascdesc=desc&srchfid[0]=all&page=%ld", key, random ?: @"title", page];
            break;
        }
        case HPSearchTypeFullText:
        {
            NSString *key = [parameters objectForKey:@"key"];
            path = [NSString stringWithFormat:@"forum/search.php?srchtype=fulltext&srchtxt=%@&searchsubmit=true&st=on&srchuname=&srchfilter=all&srchfrom=0&before=&orderby=lastpost&ascdesc=desc&page=%ld", key, page];
            break;
        }
        case HPSearchTypeUserTopic:
        {
            NSString *key = [parameters objectForKey:@"key"];
            if (page == 1) {
                 path = [NSString stringWithFormat:@"forum/search.php?srchuid=%@&srchfid=all&srchfrom=0&searchsubmit=yes&page=%ld", key, page];
            } else {
                 path = [NSString stringWithFormat:@"forum/search.php?searchid=%@&orderby=lastpost&ascdesc=desc&searchsubmit=yes&page=%@", @(searchid), @(page)];
            }
            break;
        }
        default:
            NSLog(@"error HPSearchType %ld", type);
            break;
    }

    [[HPHttpClient sharedClient] getPathContent:path parameters:nil success:^(AFHTTPRequestOperation *operation, NSString *html)
     {         
         if(DEBUG_Search) NSLog(@"html %@", html);
         
         NSMutableArray *results = [NSMutableArray arrayWithCapacity:50];
         NSString *pattern = nil;
         NSArray *props = nil;
         
         switch (type) {
             case HPSearchTypeTitle:
             case HPSearchTypeUserTopic:
             {
                 pattern = @"th class=\"subject.*?<a href=\"viewthread\\.php\\?tid=(\\d+)[^>]+>(.*?)</a>.*?fid=(\\d+)\">(.*?)</a>.*?uid=(\\d+)\">(.*?)</a>.*?<em>(.*?)</em>";
                 
                 props = @[@"tidString", @"title",
                           @"fidString", @"forum",
                           @"uidString", @"username",
                           @"dateString"];
                 
                 break;
             }
             case HPSearchTypeFullText:
             {
                 pattern = @"<a href=\"gotopost\\.php\\?pid=(\\d+)\" target=\"_blank\">(.*?)</a>.*?sp_content\">(.*?)</div>.*?fid=(\\d+)\">(.*?)</a>.*?uid=(\\d+)\">(.*?)</a>";
                 
                 props = @[@"pidString", @"title", @"detail",
                           @"fidString", @"forum",
                           @"uidString", @"username"];
                 break;
             }
             default:
                 NSLog(@"error HPSearchType %ld", type);
                 break;
         }
         NSRegularExpression *reg =
         [[NSRegularExpression alloc] initWithPattern:pattern
                                              options:NSRegularExpressionDotMatchesLineSeparators
                                                error:nil];
         
         NSArray *matches = [reg matchesInString:html
                                         options:0
                                           range:NSMakeRange(0, [html length])];
         
         
         if(DEBUG_Search)  NSLog(@"threads matches count %ld", [matches count]);
         
         for (NSTextCheckingResult *result in matches) {
             
             if ([result numberOfRanges] == [props count] + 1) {
                 
                 NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[props count]];
                 
                 for (int i=0; i < [props count]; i++) {
                     NSString *prop = [props objectAtIndex:i];
                     
                     NSRange range = NSMakeRange([result rangeAtIndex:i+1].location, [result rangeAtIndex:i+1].length);
                     NSString *value = [html substringWithRange:range];
                     
                     //<em style="color:red;">软件</em>
                     // 『』
                     // \n
                     if ([prop isEqualToString:@"title"] || [prop isEqualToString:@"detail"]) {
                         value = value ?: @"";
                         NSMutableString *raw = [NSMutableString stringWithString:value];
                         
                         //
                         [raw replaceOccurrencesOfString:@"\n" withString:@"  " options:NSLiteralSearch range:NSMakeRange(0, [raw length])];
                         [raw replaceOccurrencesOfString:@"\r" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [raw length])];
                         
                         //
                         NSString *left = @"<em style=\"color:red;\">";
                         NSString *right = @"</em>";
                         NSString *pattern = [NSString stringWithFormat:@"%@(.*?)%@", left, right];
                         
                         NSArray *matches = [RX(pattern) matchesWithDetails:raw];
                         NSMutableArray *ranges = [NSMutableArray array];
                         
                         NSInteger offset = 0;
                         for (RxMatch *m in matches) {
                             NSRange r = [m.groups[1] range];
                             r = NSMakeRange(r.location - left.length - offset, r.length);
                             offset += (left.length + right.length);
                             [ranges addObject:[NSValue valueWithRange:r]];
                         }
                         
                         [raw replaceOccurrencesOfString:left withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [raw length])];
                         [raw replaceOccurrencesOfString:right withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [raw length])];
                         
                         NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:raw];
                         for (NSValue *v in ranges) {
                             [attr addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:[v rangeValue]];
                         }
                        
                         [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:HPSearch_FONT_SIZE] range:NSMakeRange(0, [attr length])];
                         
                         value = [attr copy];
                     }
                     
                     [dict setObject:value forKey:prop];
                 }
                 
                 
                 if(DEBUG_Search) NSLog(@"dict %@", dict);
                 
                 [results addObject:dict];
                 
             } else {
                 NSLog(@"error %@ %ld", result, [result numberOfRanges]);
             }
         }
         
         NSString *url = [operation.response.URL absoluteString];
         searchid = [[url stringBetweenString:@"searchid=" andString:@"&"] integerValue];
         
         //搜索用户时, 每页不一定是50条, 所以算出来的页数比实际页数多
         NSInteger pageCount = 0;
         NSArray *ms = [RX(@"page=(\\d+)\"( class=\"last\")?>") matchesWithDetails:html];
         for (RxMatch *m in ms) {
             RxMatchGroup *g1 = [m.groups objectAtIndex:1];
             NSInteger i = [g1.value integerValue];
             if (i > pageCount) {
                 pageCount = i;
             }
         }
         pageCount = MAX(pageCount, page);
         
         if (block) {
             block([NSArray arrayWithArray:results], pageCount, nil);
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if (block) {
             block([NSArray array], 0, error);
         }
     }];
}


@end
