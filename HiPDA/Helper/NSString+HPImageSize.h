//
//  NSString+HPImageSize.h
//  HiPDA
//
//  Created by Jiangfan on 16/3/27.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HPImageSize)

- (NSString*)getSizeString:(NSString *)aid;
- (NSString*)getFuckSizeString:(NSString *)aid;

- (CGFloat)imageSize;
- (NSString *)imageSizeString;

@end;