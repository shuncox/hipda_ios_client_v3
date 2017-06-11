//
//  HPImageNode.h
//  HiPDA
//
//  Created by Jiangfan on 2017/6/11.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPImageNode : NSObject

@property (nonatomic, readonly, strong) NSString *id;

- (instancetype)initWithURL:(NSString *)url;

- (NSString *)hp_thumbnailURL;
- (NSString *)hp_URL;

@end

@interface NSArray (HPImageNode)

- (NSArray<NSString *> *)hp_imageThumbnailURLs;
- (NSArray<NSString *> *)hp_imageURLs;

@end
