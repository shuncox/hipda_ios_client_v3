//
//  HPPDFPreviewViewController.h
//  HiPDA
//
//  Created by Jiangfan on 2017/6/10.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPPDFPreviewViewController : UIViewController

+ (void)presentInViewController:(UIViewController *)viewController
                        pdfData:(NSData *)pdfData;

@end
