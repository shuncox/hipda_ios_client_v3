//
//  HPApiPage.h
//  HiPDA
//
//  Created by Jiangfan on 2018/9/15.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPApiPage : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSArray *list;
@property (nonatomic, assign) int totalElements;
@property (nonatomic, assign) int totalPages;
@property (nonatomic, assign) int pageSize;
@property (nonatomic, assign) int pageIndex;
@property (nonatomic, readonly, assign) BOOL isEnd;

@end
