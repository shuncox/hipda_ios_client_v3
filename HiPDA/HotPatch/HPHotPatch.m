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
        
        //每个app 版本对应一个db
        NSString *db = [NSString stringWithFormat:@"hotpatch_%@.ldb", VERSION];
        _db = [LevelDB databaseInLibraryWithName:db];
        
        NSString *url = @"http://7xnvdg.com1.z0.glb.clouddn.com/patch";
#ifdef DEBUG
        url = @"http://127.0.0.1:8000";
#endif
        _client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:url]];
        
        //
        [JPEngine startEngine];
        
        // error log
        JSContext *context = [JPEngine context];
        context[@"_OC_catch"] = ^(JSValue *msg, JSValue *stack) {
            NSAssert(NO, @"oc exception, \nmsg: %@, \nstack: \n %@", [msg toObject], [stack toObject]);
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
    
#ifdef DEBUG
    NSLog(@"######## patch in db #########");
    [self.db enumerateKeysAndObjectsUsingBlock:^(LevelDBKey *key, id value, BOOL *stop) {
        NSLog(@"key: %@ - value: %@", NSStringFromLevelDBKey(key), value);
    }];
    NSLog(@"######## patch in db #########");
#endif
    
    /*
     * patch 更新, 清除, 请使用新的或空的patch文件, 相同url, 来置换
     */
    
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
        
        __block NSInteger validPatchCount = 0;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            dispatch_group_t downloadGroup = dispatch_group_create();
            for (NSString *url in config.patches) {
                
                dispatch_group_enter(downloadGroup);
                
                [self.client getPath:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    NSString *script = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                    
                    // script 必须以 '//{config.version}' 开头, 用来校验patch的版本
                    // 防止 在某些情况下, 需要更新patch文件, 但是由于CDN延迟, patch文件还是旧的, 但是config却保存下来, 下次误判为最新的, 不再更新patch
                    if ([script hasPrefix:[NSString stringWithFormat:@"//%@", @(config.version)]]) {
                        
                        //
                        validPatchCount++;
                        
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
                    }
                    
                    dispatch_group_leave(downloadGroup);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    ;
                    dispatch_group_leave(downloadGroup);
                }];
            }
            
            dispatch_group_wait(downloadGroup, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (validPatchCount == config.patches.count) {
                    db[@"config"] = config;
                }
            });
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ;
    }];
}

@end
