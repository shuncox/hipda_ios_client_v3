//
//  HPApiThread.h
//  HiPDA
//
//  Created by Jiangfan on 2018/9/15.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPApiThread : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) int tid;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) int uid;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, assign) int created;

@end
