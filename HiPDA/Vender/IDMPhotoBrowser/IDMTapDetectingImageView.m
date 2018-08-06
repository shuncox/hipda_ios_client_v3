//
//  IDMTapDetectingImageView.m
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 04/11/2009.
//  Copyright 2009 d3i. All rights reserved.
//

#import "IDMTapDetectingImageView.h"

@implementation IDMTapDetectingImageView

@synthesize tapDelegate;

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		self.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];

        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];

        [singleTap requireGestureRecognizerToFail:doubleTap];
        
        UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongTap:)];
        [self addGestureRecognizer:longPress];
	}
	return self;
}

- (id)initWithImage:(UIImage *)image {
	if ((self = [super initWithImage:image])) {
		self.userInteractionEnabled = YES;
	}
	return self;
}

- (id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
	if ((self = [super initWithImage:image highlightedImage:highlightedImage])) {
		self.userInteractionEnabled = YES;
	}
	return self;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)singleTap {
	if ([tapDelegate respondsToSelector:@selector(imageView:singleTapDetected:)])
		[tapDelegate imageView:self singleTapDetected:singleTap];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)doubleTap {
	if ([tapDelegate respondsToSelector:@selector(imageView:doubleTapDetected:)])
		[tapDelegate imageView:self doubleTapDetected:doubleTap];
}

- (void)handleLongTap:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state != UIGestureRecognizerStateBegan) {
        return;
    }
    if ([tapDelegate respondsToSelector:@selector(imageView:longTapDetected:)])
        [tapDelegate imageView:self longTapDetected:longPress];
}

- (void)dealloc
{
    
}
@end
