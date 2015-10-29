//
//  HPDebugCrawlerViewController.h
//  HiPDA
//
//  Created by Jichao Wu on 15/10/29.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPDebugCrawlerViewController : UIViewController

@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) HPCrawlerErrorContext *context;

@end
