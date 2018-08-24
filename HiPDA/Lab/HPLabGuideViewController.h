//
//  HPLabGuideViewController.h
//  HiPDA
//
//  Created by Jiangfan on 2018/8/11.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPLabGuideViewController : UIViewController

+ (void)presentIn:(UIViewController *)parent;

@property (nonatomic, assign) BOOL isModal; //TODO

@end
