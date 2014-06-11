//
//  UIWebView+Capture.m
//  HiPDA
//
//  Created by wujichao on 14-6-11.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "UIWebView+Capture.h"
#import "UIView+ScreenShot.h"

@implementation UIWebView (Capture)

- (UIImage*)capture;
{
    int webViewHeight = [[self stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight;"] integerValue];
    int scrollByY = self.frame.size.height;
    int imageName = 0;
    
    int y = IOS7_OR_LATER ? 64 : 0;
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollTo(0,%d);", y]];
    
    NSMutableArray* images = [[NSMutableArray alloc] init];
    
    CGRect screenRect = self.frame;
    double currentWebViewHeight = webViewHeight;
    while (currentWebViewHeight > 0)
    {
        imageName ++;
        
        //UIGraphicsBeginImageContext(screenRect.size);
        UIGraphicsBeginImageContextWithOptions(screenRect.size, NO, 0.0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [[UIColor blackColor] set];
        CGContextFillRect(ctx, screenRect);
        
        [self.layer renderInContext:ctx];
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if(currentWebViewHeight < scrollByY)
        {
            CGRect lastImageRect = CGRectMake(0, scrollByY - currentWebViewHeight, self.frame.size.width, currentWebViewHeight);
            
            
            
            CGImageRef imageRef = CGImageCreateWithImageInRect([newImage CGImage], lastImageRect);
            
            //newImage = [UIImage imageWithCGImage:imageRef];
            //newImage = [UIImage imageWithCGImage:imageRef scale:2.0 orientation:newImage.imageOrientation];
            newImage = [self imageFromImage:newImage inRect:lastImageRect];
            CGImageRelease(imageRef);
            
        }
        [images addObject:newImage];
        
        [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0,%d);", scrollByY]];
        currentWebViewHeight -= scrollByY;
    }
    
    [self stringByEvaluatingJavaScriptFromString:@"window.scrollTo(0,0);"];
    
    //[images addObject:[[self infoView] screenShot]];
    
    UIImage *resultImage;
    
    if(images.count > 1) {
        //join all images together..
        CGSize sz;
        for(int i=0;i<images.count;i++) {
            
            sz.width = MAX(sz.width, ((UIImage*)[images objectAtIndex:i]).size.width );
            sz.height += ((UIImage*)[images objectAtIndex:i]).size.height;
        }
        
        //UIGraphicsBeginImageContext(sz);
        UIGraphicsBeginImageContextWithOptions(sz, NO, 0.0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [[UIColor blackColor] set];
        CGContextFillRect(ctx, screenRect);
        
        int y=0;
        for(int i=0;i<images.count;i++) {
            
            UIImage* img = [images objectAtIndex:i];
            [img drawAtPoint:CGPointMake(0,y)];
            y += img.size.height;
        }
        
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } else {
        
        resultImage = [images objectAtIndex:0];
    }
    
    return resultImage;
    
}

- (UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect {
    rect.size.height = rect.size.height * [image scale];
    rect.size.width = rect.size.width * [image scale];
    rect.origin.x = rect.origin.x * [image scale];
    rect.origin.y = rect.origin.y * [image scale];
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:[image scale] orientation:[image imageOrientation]];
    CGImageRelease(newImageRef);
    return newImage;
}

- (UIView *)infoView {
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100)];
    view.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:view.frame];
    [view addSubview:label];
    label.numberOfLines = 0;
    label.text = @"http://stackoverflow.com/questions/2765537/how-do-i-use-the-nsstring-draw-functionality-to-create-a-uiimage-from-text";
    [label sizeToFit];
    
    return view;
}


@end
