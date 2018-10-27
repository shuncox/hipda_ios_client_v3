//
//  HPAttachmentService.h
//  HiPDA
//
//  Created by Jiangfan on 2018/10/27.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPAttachmentService : NSObject

- (instancetype)initWithUrl:(NSString *)url
                   parentVC:(UIViewController *)parentVC;

- (void)start;

@end
