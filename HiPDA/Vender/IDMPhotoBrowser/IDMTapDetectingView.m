//
//  IDMTapDetectingView.m
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 04/11/2009.
//  Copyright 2009 d3i. All rights reserved.
//

#import "IDMTapDetectingView.h"

@implementation IDMTapDetectingView

- (id)init {
	if ((self = [super init])) {
		self.userInteractionEnabled = YES;
	}
	return self;
}

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
	}
	return self;
}

- (void)handleSingleTap:(UITouch *)touch {
	if ([self.tapDelegate respondsToSelector:@selector(view:singleTapDetected:)])
		[self.tapDelegate view:self singleTapDetected:touch];
}

- (void)handleDoubleTap:(UITouch *)touch {
	if ([self.tapDelegate respondsToSelector:@selector(view:doubleTapDetected:)])
		[self.tapDelegate view:self doubleTapDetected:touch];
}

- (void)dealloc
{
    
}
@end
