//
//  UMOnlineConfig+BOOL.h
//  HiPDA
//
//  Created by Jichao Wu on 15/12/7.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "UMOnlineConfig.h"

@interface UMOnlineConfig (BOOL)

+ (BOOL)getBoolConfigWithKey:(NSString *)key defaultYES:(BOOL)defaultYES;
+ (NSInteger)getIntegerConfigWithKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
+ (BOOL)hasConfigForKey:(NSString *)key;

@end
