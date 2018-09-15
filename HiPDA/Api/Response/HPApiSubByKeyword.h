//
//  HPApiSubByKeyword.h
//  HiPDA
//
//  Created by Jiangfan on 2018/9/15.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPApiSubByKeyword : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString *keyword;

@end
