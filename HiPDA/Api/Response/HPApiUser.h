//
//  HPApiUser.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/9.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPApiUser : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *cookies;

@end
