//
//  NSRegularExpression+HP.h
//  HiPDA
//
//  Created by Jiangfan on 16/3/13.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegExCategories.h"

@interface NSRegularExpression (HP)

- (NSString *)firstMatchValue:(NSString*)str;

@end
