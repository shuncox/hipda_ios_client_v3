//
//  HPApiPage.h
//  HiPDA
//
//  Created by Jiangfan on 2018/9/15.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPApiPage<T> : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSArray<T> *content;
@property (nonatomic, assign) BOOL last; //isEnd
@property (nonatomic, assign) int totalPages;
@property (nonatomic, assign) int size; //pageSize
@property (nonatomic, assign) int number; //pageIndex

@end
