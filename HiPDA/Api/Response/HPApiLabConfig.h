//
//  HPApiLabConfig.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/23.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface HPApiLabConfig : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString *alert;
@property (nonatomic, strong) NSString *noticeHtml;
@property (nonatomic, strong) NSString *notice;
@property (nonatomic, assign) BOOL disableMessagePush;
@property (nonatomic, assign) BOOL disableSubscribe;

@end
