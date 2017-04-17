//
//  HPJSMessage.h
//  HiPDA
//
//  Created by Jiangfan on 2017/4/17.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface HPJSMessage : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *method;
@property (nonatomic, strong) id object;

@end
