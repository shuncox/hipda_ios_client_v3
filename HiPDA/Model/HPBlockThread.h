//
//  HPBlockThread.h
//  HiPDA
//
//  Created by Jiangfan on 2019/10/19.
//  Copyright © 2019 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPBlockThread : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSInteger fid;
@property (nonatomic, assign) NSInteger tid;
@property (nonatomic, strong) NSString *title;

@end
