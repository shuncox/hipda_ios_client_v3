//
//  HPHotPatch.h
//  HiPDA
//
//  Created by Jichao Wu on 15/7/23.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<JSPatch/RenamePrefix.h>)
#import <JSPatch/RenamePrefix.h>
#endif
#import <JSPatch/JPEngine.h>

@interface HPHotPatch : NSObject

+ (HPHotPatch *)shared;
- (void)check;

@end
