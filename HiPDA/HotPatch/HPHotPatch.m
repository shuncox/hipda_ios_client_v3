//
//  HPHotPatch.m
//  botofans
//
//  Created by Jichao Wu on 15/6/11.
//  Copyright (c) 2015年 Jichao Wu. All rights reserved.
//

#import "HPHotPatch.h"
#import "MobClick.h"
#import <Mantle.h>
#import <LevelDB.h>
#import <AFHTTPClient.h>

#define VERSION ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"])
#define BUILD ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"])

@interface PatchConfig : MTLModel <MTLJSONSerializing>
@property (nonatomic, assign)double version;
@property (nonatomic, strong)NSArray *patches;
@end

@implementation PatchConfig
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"version": @"version",
             @"patches": @"patches"
             };
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isMemberOfClass:self.class]) return NO;
    
    return self.version == ((PatchConfig *)object).version;
}

@end

@interface HPHotPatch()

@property (nonatomic, strong)LevelDB *db;
@property (nonatomic, strong)AFHTTPClient *client;

@end

@implementation HPHotPatch

+ (HPHotPatch *)shared
{
    static dispatch_once_t once;
    static HPHotPatch *singleton;
    dispatch_once(&once, ^ { singleton = [[HPHotPatch alloc] init]; });
    return singleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        //
        _db = [LevelDB databaseInLibraryWithName:@"hotpatch.ldb"];
        _client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://hpclient.qiniudn.com/patch"]];
        
        //
        [JPEngine startEngine];
        
        // error log
        JSContext *context = [JPEngine context];
        context[@"_OC_catch"] = ^(JSValue *msg, JSValue *stack) {
            NSAssert(NO, @"js exception, \nmsg: %@, \nstack: \n %@", [msg toObject], [stack toObject]);
            [MobClick event:@"_OC_catch" attributes:@{@"msg":[msg toObject], @"stack":[stack toObject]}];
        };
        
        context.exceptionHandler = ^(JSContext *con, JSValue *exception) {
            NSAssert(NO, @"js exception: %@", exception);
            [MobClick event:@"_js_exception" attributes:@{@"exception": exception?:@"null"}];
        };
        
#ifdef DEBUG
        NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"debug-hotpatch" ofType:@"js"];
        NSString *script = [NSString stringWithContentsOfFile:sourcePath encoding:NSUTF8StringEncoding error:nil];
        [JPEngine evaluateScript:script];
#endif
    }
    return self;
}

- (void)check {
    
    NSLog(@"hotpatch check...");
    
    LevelDB *db = self.db;
    
    // patch what we have
    PatchConfig *old_config = db[@"config"];
    
    // 只patch一次(app 启动时)
    static BOOL first = YES;
    if (first) {
        first = !first;
        NSLog(@"old_config: %@", old_config);
        if (old_config) {
            for (NSString *url in old_config.patches) {
                NSString *js = db[url];
                NSLog(@"patch %@: %@", url, js);
                if (js.length) {
                    [JPEngine evaluateScript:js];
                }
            }
        }
    }
    
    // update config
    NSString *url = [NSString stringWithFormat:@"patch_config_%@.json", VERSION];
    [self.client getPath:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
        
        PatchConfig *config = [MTLJSONAdapter modelOfClass:PatchConfig.class
                                        fromJSONDictionary:json
                                                     error:&error];
        NSLog(@"get new patch: %@", config);
        if (error) {
            NSLog(@"%@", error);
            return;
        }
        
        if (config.version <= old_config.version) {
            NSLog(@"config.version <= old_config.version, %@ %@", config, old_config);
            return;
        }
        
        db[@"config"] = config;
        for (NSString *url in config.patches) {
            
            [self.client getPath:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSString *script = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                
                // save
                db[url] = script;
                
                NSLog(@"patch %@: %@", url, script);
                // 只patch新的 已经patch的忽略(小心新旧冲突)  然后等下次patch
                if ([old_config.patches containsObject:url]) {
                    NSLog(@"pass");
                } else {
                    NSLog(@"patch");
                    if (script.length) {
                        [JPEngine evaluateScript:script];
                    }
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                ;
            }];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ;
    }];
}

@end
