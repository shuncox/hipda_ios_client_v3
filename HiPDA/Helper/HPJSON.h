//
//  HPJSON.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/12.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPJSON : NSObject

+ (NSDictionary *)fromJSON:(NSString *)jsonString;
+ (NSString *)toJSON:(NSDictionary *)dic;

+ (MTLModel<MTLJSONSerializing> *)mtl_fromJSON:(NSString *)jsonString
                                         class:(Class)clazz;
+ (NSString *)mtl_toJSON:(MTLModel<MTLJSONSerializing> *)object;

@end
