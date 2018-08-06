//
//  IDMTapDetectingImageView.h
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 04/11/2009.
//  Copyright 2009 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IDMTapDetectingImageViewDelegate;

@interface IDMTapDetectingImageView : UIImageView {
	id <IDMTapDetectingImageViewDelegate> __weak tapDelegate;
}
@property (nonatomic, weak) id <IDMTapDetectingImageViewDelegate> tapDelegate;
@end

@protocol IDMTapDetectingImageViewDelegate <NSObject>
@optional
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITapGestureRecognizer *)singleTap;
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITapGestureRecognizer *)doubleTap;
- (void)imageView:(UIImageView *)imageView longTapDetected:(UILongPressGestureRecognizer *)longPress;
@end
