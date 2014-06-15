//
//  HPEditPostViewController.h
//  HiPDA
//
//  Created by wujichao on 14-6-15.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPBaseCompostionViewController.h"

@class HPNewPost;

@interface HPEditPostViewController : HPBaseCompostionViewController

- (id)initWithPost:(HPNewPost *)post
        actionType:(ActionType)type
            thread:(HPThread *)thread
              page:(NSInteger)page
          delegate:(id<HPCompositionDoneDelegate>)delegate;

@end
