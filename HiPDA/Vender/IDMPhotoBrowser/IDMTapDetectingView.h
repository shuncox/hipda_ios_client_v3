//
//  IDMTapDetectingView.h
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 04/11/2009.
//  Copyright 2009 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IDMTapDetectingViewDelegate;

@interface IDMTapDetectingView : UIView

@property (nonatomic, weak) id <IDMTapDetectingViewDelegate> tapDelegate;
@end

@protocol IDMTapDetectingViewDelegate <NSObject>
@optional
- (void)view:(UIView *)view singleTapDetected:(UITapGestureRecognizer *)singleTap;
- (void)view:(UIView *)view doubleTapDetected:(UITapGestureRecognizer *)doubleTap;
@end
