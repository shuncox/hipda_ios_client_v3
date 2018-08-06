//
//  IDMZoomingScrollView.m
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "IDMZoomingScrollView.h"
#import "IDMPhotoBrowser.h"
#import "IDMPhoto.h"

@implementation UIScrollView (ZoomToPoint)
- (void)zoomToPoint:(CGPoint)zoomPoint withScale: (CGFloat)scale animated: (BOOL)animated
{
    CGRect zrect = [self zoomRectForScrollView:self withScale:scale withCenter:zoomPoint];
    [self zoomToRect:zrect animated:YES];
}
- (CGRect)zoomRectForScrollView:(UIScrollView *)scrollView withScale:(CGFloat)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the
    // imageScrollView's bounds.
    // As the zoom scale decreases, so more content is visible,
    // the size of the rect grows.
    zoomRect.size.height = scrollView.frame.size.height / scale;
    zoomRect.size.width = scrollView.frame.size.width / scale;
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    return zoomRect;
}
@end

// Declare private methods of browser
@interface IDMPhotoBrowser ()
- (UIImage *)imageForPhoto:(id<IDMPhoto>)photo;
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)toggleControls;
@end

// Private methods and properties
@interface IDMZoomingScrollView ()
@property (nonatomic, weak) IDMPhotoBrowser *photoBrowser;
- (void)handleSingleTap:(CGPoint)touchPoint;
- (void)handleDoubleTap:(CGPoint)touchPoint;
@end

@implementation IDMZoomingScrollView

@synthesize photoImageView = _photoImageView, photoBrowser = _photoBrowser, photo = _photo, captionView = _captionView;

- (id)initWithPhotoBrowser:(IDMPhotoBrowser *)browser {
    if ((self = [super init])) {
        // Delegate
        self.photoBrowser = browser;
        
		// Tap view for background
		_tapView = [[IDMTapDetectingView alloc] initWithFrame:self.bounds];
		_tapView.tapDelegate = self;
		_tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tapView.backgroundColor = [UIColor clearColor];
		[self addSubview:_tapView];
        
		// Image view
		_photoImageView = [[IDMTapDetectingImageView alloc] initWithFrame:CGRectZero];
		_photoImageView.tapDelegate = self;
		_photoImageView.backgroundColor = [UIColor clearColor];
		[self addSubview:_photoImageView];
        
        CGRect screenBound = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenBound.size.width;
        CGFloat screenHeight = screenBound.size.height;
        
        if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
            [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
            screenWidth = screenBound.size.height;
            screenHeight = screenBound.size.width;
        }
        
        // Progress view
        _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake((screenWidth-35.)/2., (screenHeight-35.)/2, 35.0f, 35.0f)];
        [_progressView setProgress:0.02f];
        _progressView.tag = 101;
        _progressView.thicknessRatio = 0.1; //SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7") ? 0.1 : 0.2;
        _progressView.roundedCorners = NO;  //SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7") ? NO  : YES;
        _progressView.trackTintColor    = browser.trackTintColor    ? self.photoBrowser.trackTintColor    : [UIColor colorWithWhite:0.2 alpha:1];
        _progressView.progressTintColor = browser.progressTintColor ? self.photoBrowser.progressTintColor : [UIColor colorWithWhite:1.0 alpha:1];
        [self addSubview:_progressView];
        
		// Setup
		self.backgroundColor = [UIColor clearColor];
		self.delegate = self;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return self;
}

- (void)setPhoto:(id<IDMPhoto>)photo {
    _photoImageView.image = nil; // Release image
    if (_photo != photo) {
        _photo = photo;
    }
    [self displayImage];
}

- (void)prepareForReuse {
    self.photo = nil;
    [_captionView removeFromSuperview];
    self.captionView = nil;
}

#pragma mark - Image

// Get and display image
- (void)displayImage {
	if (_photo /*&& _photoImageView.image == nil*/) {
        
        BOOL needReset = _photoImageView.image == nil;
        if (needReset) {
            // Reset
            self.maximumZoomScale = 1;
            self.minimumZoomScale = 1;
            self.zoomScale = 1;
            
            self.contentSize = CGSizeMake(0, 0);
        }
		
		// Get image from browser as it handles ordering of fetching
		UIImage *img = [self.photoBrowser imageForPhoto:_photo];
		if (img) {
            // Hide ProgressView
            //_progressView.alpha = 0.0f;
            
            // 先小图后大图, 加载大图时保留进度条
            if (!_photo.loadingOriginalImage) {
                [_progressView removeFromSuperview];
            }
            
            // Set image
			_photoImageView.image = img;
			_photoImageView.hidden = NO;
            
            if (needReset) {
                // Setup photo frame
                CGRect photoImageViewFrame;
                photoImageViewFrame.origin = CGPointZero;
                photoImageViewFrame.size = img.size;
                
                _photoImageView.frame = photoImageViewFrame;
                self.contentSize = photoImageViewFrame.size;
                
                // Set zoom to minimum zoom
                [self setMaxMinZoomScalesForCurrentBounds];
            }
        } else {
			// Hide image view
			_photoImageView.hidden = YES;
            
            _progressView.alpha = 1.0f;
		}
        
		[self setNeedsLayout];
	}
}

- (void)setProgress:(CGFloat)progress forPhoto:(IDMPhoto*)photo {
    IDMPhoto *p = (IDMPhoto*)self.photo;

    if ([photo.photoURL.absoluteString isEqualToString:p.photoURL.absoluteString]) {
        if (_progressView.progress < progress) {
            [_progressView setProgress:progress animated:YES];
        }
    }
}

// Image failed so just show black!
- (void)displayImageFailure {
    [_progressView removeFromSuperview];
    // todo reload
    //[photo loadUnderlyingImageAndNotify];
}

#pragma mark - Setup

- (void)setMaxMinZoomScalesForCurrentBounds {
	// Reset
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.zoomScale = 1;
    
	// Bail
	if (_photoImageView.image == nil) return;
    
	// Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.frame.size;
    
    // Calculate
    /*
     缩放策略
        初始铺满屏幕, 无论图片大小, 大的缩小(scale<1), 小的放大(scale>1)
        最大为 MAX(屏幕尺寸的两倍, 原图的两倍)
        长图(h/w>3) -> 初始宽为屏幕大小
     */
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    BOOL isChangTu/*长图*/ = imageSize.height / imageSize.width > 3.f;
    if (isChangTu) {
        minScale = xScale;
    }
    // max.target.w = max(image.w * 2, screen.w * 2)
    // max.scale = max.target.w / image.w = max(2, minScale*2)
    CGFloat maxScale = MAX(2, minScale * 2);
    
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
	self.zoomScale = minScale;

    if (isChangTu) {
        self.contentOffset = CGPointMake(0, 0);
    }
    
	// Reset position
	_photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
	[self setNeedsLayout];    
}

#pragma mark - Layout

- (void)layoutSubviews {
	// Update tap view frame
	_tapView.frame = self.bounds;
    
	// Super
	[super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
	// Center
	if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
		_photoImageView.frame = frameToCenter;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[_photoBrowser hideControlsAfterDelay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection

//- (void)handleSingleTap:(CGPoint)touchPoint {
////    [_photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
//}

- (void)handleDoubleTap:(CGPoint)touchPoint {
	
	// Cancel any single tap handling
	[NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
	
	// Zoom
    // 初始状态 self.minimumZoomScale = self.zoomScale
    // 然后在`缩放到屏幕两倍`到`缩放的屏幕大小`之间切换
	if (self.zoomScale > self.minimumZoomScale) {
		// Zoom out
		[self setZoomScale:self.minimumZoomScale animated:YES];
	} else {
		// Zoom in
		[self zoomToPoint:touchPoint withScale:self.minimumZoomScale * 2 animated:YES];
	}
	
	// Delay controls
	[_photoBrowser hideControlsAfterDelay];
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITapGestureRecognizer *)singleTap {
//    [self handleSingleTap:[touch locationInView:imageView]];
    [_photoBrowser doneButtonPressed:imageView];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITapGestureRecognizer *)doubleTap {
    [self handleDoubleTap:[doubleTap locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView longTapDetected:(UILongPressGestureRecognizer *)longPress {
    [_photoBrowser actionButtonPressed:imageView];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITapGestureRecognizer *)singleTap {
    //[self handleSingleTap:[touch locationInView:view]];
    [_photoBrowser doneButtonPressed:view];
}
- (void)view:(UIView *)view doubleTapDetected:(UITapGestureRecognizer *)doubleTap {
    [self handleDoubleTap:[doubleTap locationInView:view]];
}

- (void)dealloc
{
    
}

@end
