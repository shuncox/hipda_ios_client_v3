//
//  HPLabUser.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPLabUser : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) int userId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *token;

@end
