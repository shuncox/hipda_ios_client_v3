//
//  HPUserSearch.h
//  HiPDA
//
//  Created by Jiangfan on 2017/5/16.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>

@interface HPUserSearch : NSObject

+ (RACSignal *)signalForSearchUserWithKey:(NSString *)key;

@end
